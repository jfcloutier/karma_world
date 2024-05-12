defmodule KarmaWorld.Playground do
  @moduledoc """
  Where the robots play.
  A square grid of equilateral tiles arranged in rows, with row 0 "down" and column 0 "left".any()
  North is up at 270 degrees. East is right at 0 degrees.
  """

  use GenServer

  alias KarmaWorld.{Playground, Space, Tile, Robot}
  require Logger

  @type t :: %__MODULE__{
          # A list of rows of tiles
          tiles: [[Tile.t()]],
          robots: map()
        }

  @type food :: %{
          # the tile at the center of the food patch
          tile: %{row: non_neg_integer(), column: non_neg_integer()},
          # how much "food-seconds" the food started with
          duration: integer(),
          # for how long the food patch has been cumulatively occupied
          total_occupied: integer()
        }

  @check_food_delay_secs 1

  defstruct tiles: [],
            robots: %{},
            food: nil

  @doc "Get playground defaults"
  @spec defaults() :: keyword()
  def defaults(), do: Application.get_env(:karma_world, :playground)

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @spec start_link :: GenServer.on_start()
  def start_link() do
    Logger.info("Starting #{inspect(__MODULE__)}")
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    tiles = init_tiles()
    initial_state = reset_food(%__MODULE__{tiles: tiles})
    Process.send_after(self(), :check_food, @check_food_delay_secs * 1000)
    {:ok, initial_state}
  end

  @doc """
  Put the food center tile at a specific position. Used for testing.
  """
  @spec make_food(
          row: non_neg_integer(),
          column: non_neg_integer(),
          food_duration: non_neg_integer()
        ) ::
          :ok | {:error, :invalid}
  def make_food(row: row, column: column, food_duration: food_duration),
    do: GenServer.call(__MODULE__, {:make_food, row, column, food_duration})

  @doc """
  Place a robot in the playground
  """
  @spec place_robot(map()) :: {:ok, Robot.t()} | {:error, atom()}
  def place_robot(%{name: name, row: row, column: column, orientation: orientation}),
    do:
      GenServer.call(
        __MODULE__,
        {:place_robot, name: name, row: row, column: column, orientation: orientation}
      )

  @doc """
  Add a device to a robot
  """
  @spec add_device(any(), map()) :: :ok
  def add_device(robot_name, device_data),
    do:
      GenServer.cast(__MODULE__, {:add_device, robot_name: robot_name, device_data: device_data})

  @doc """
  Add an action to the pending actions
  """
  @spec actuate(keyword()) :: :ok
  def actuate(name: robot_name, device_id: motor_id, action: action),
    do: GenServer.call(__MODULE__, {:actuate, robot_name, motor_id, action})

  @doc """
  Execute pending actions
  """
  @spec execute_actions(keyword()) :: :ok
  def execute_actions(name: robot_name),
    do: GenServer.call(__MODULE__, {:execute_actions, robot_name})

  @doc """
  Read a sensor
  """
  @spec sense(keyword()) :: any()
  def sense(name: robot_name, sensor_id: sensor_id, sense: sense),
    do: GenServer.call(__MODULE__, {:sense, robot_name, sensor_id, sense})

  # Test support
  @doc false
  @spec tiles() :: [[Tile.t()]]
  def tiles(), do: GenServer.call(__MODULE__, :tiles)

  # Test support
  @doc false
  @spec food() :: map()
  def food(), do: GenServer.call(__MODULE__, :food)

  # Test support
  @doc false
  @spec robots() :: [Robot.t()]
  def robots(), do: GenServer.call(__MODULE__, :robots)

  # Test support
  @doc false
  @spec robot(String.t()) :: {:ok, Robot.t()} | :error
  def robot(robot_name), do: GenServer.call(__MODULE__, {:robot, robot_name})

  # Test support
  @doc false
  @spec clear_robots() :: :ok
  def clear_robots(), do: GenServer.cast(__MODULE__, :clear_robots)

  # Test support
  @doc false
  @spec move_robot(name: String.t(), row: non_neg_integer(), colum: non_neg_integer()) ::
          {:ok, Robot.t()} | {:error, atom()}
  def move_robot(name: robot_name, row: row, column: column),
    do: GenServer.call(__MODULE__, {:move_robot, name: robot_name, row: row, column: column})

  # Test support
  @doc false
  def orient_robot(name: robot_name, orientation: orientation),
    do:
      GenServer.call(
        __MODULE__,
        {:orient_robot, name: robot_name, orientation: orientation}
      )

  @impl GenServer

  def handle_cast(:clear_robots, state) do
    {:noreply, %{state | robots: %{}}}
  end

  def handle_cast({:add_device, robot_name: robot_name, device_data: device_data}, state) do
    robot = Map.fetch!(state.robots, robot_name)

    updated_robot = Robot.add_device(robot, device_data)
    {:noreply, %{state | robots: Map.put(state.robots, robot_name, updated_robot)}}
  end

  @impl GenServer
  def handle_info(:check_food, state) do
    updated_state = check_robot_on_food(state)

    final_state =
      if food_gone?(updated_state),
        do: reset_food(updated_state),
        else: updated_state

    Process.send_after(self(), :check_food, @check_food_delay_secs * 1000)
    {:noreply, final_state}
  end

  @impl GenServer
  # A robot is placed on the playground
  def handle_call(
        {:place_robot, name: name, row: row, column: column, orientation: orientation},
        _from,
        %{robots: robots} = state
      ) do
    case validate_and_register(
           state,
           name: name,
           row: row,
           column: column,
           orientation: orientation
         ) do
      :ok ->
        robot =
          Robot.new(
            name: name,
            orientation: orientation,
            row: row,
            column: column
          )

        Logger.info(
          "[KarmaWorld] Playground - #{name} placed at #{inspect(Robot.locate(robot))} with orientation #{orientation}"
        )

        KarmaWorld.broadcast("robot_placed", %{robot: robot, row: row, column: column})
        updated_robots = Map.put(robots, name, robot)
        {:reply, {:ok, robot}, %{state | robots: updated_robots}}

      {:error, reason} ->
        Logger.warning("[KarmaWorld] Playground - Failed to place #{name}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  # A sensor is read for a sense. Allow concurrent reads.
  def handle_call(
        {:sense, robot_name, sensor_id, sense},
        from,
        %{robots: robots, tiles: tiles} = state
      ) do
    spawn_link(fn ->
      robot = Map.fetch!(robots, robot_name)
      other_robots = Map.values(robots) -- [robot]
      value = Robot.sense(robot, sensor_id, sense, tiles, other_robots)

      Logger.info(
        "[KarmaWorld] Playground - Sensed #{inspect(sense)} of #{robot_name}'s #{inspect(sensor_id)} as #{inspect(value)}"
      )

      KarmaWorld.broadcast("robot_sensed", %{
        robot: robot,
        sensor_id: sensor_id,
        sense: sense,
        value: value
      })

      GenServer.reply(from, {:ok, value})
    end)

    {:noreply, state}
  end

  # Run a robot's motors
  def handle_call(
        {:actuate, robot_name, motor_id, action},
        _from,
        %{robots: robots, tiles: tiles} = state
      ) do
    robot = Map.fetch!(robots, robot_name)

    Logger.info("[KarmaWorld] Playground - Actuate #{robot.name}")

    actuated_robot =
      Robot.actuate(robot, motor_id, action, tiles, Map.values(robots))

    KarmaWorld.broadcast("robot_actuated", %{
      robot: actuated_robot,
      motor_id: motor_id,
      action: action
    })

    {:reply, :ok, %{state | robots: Map.put(robots, robot.name, actuated_robot)}}
  end

  def handle_call({:execute_actions, robot_name}, _from, %{robots: robots, tiles: tiles} = state) do
    robot = Map.fetch!(robots, robot_name)

    Logger.info("[KarmaWorld] Playground - Executing pending actions of #{robot.name}")
    other_robots = Map.values(robots) -- [robot]
    executed_robot = Robot.execute_actions(robot, tiles, other_robots)

    KarmaWorld.broadcast("robot_actions_executed", %{
      robot: executed_robot
    })

    {:reply, :ok, %{state | robots: Map.put(robots, robot.name, executed_robot)}}
  end

  ### TEST AND LIVE VIEW SUPPORT

  def handle_call(:tiles, _from, %{tiles: tiles} = state) do
    {:reply, tiles, state}
  end

  def handle_call(:food, _from, %{food: food} = state) do
    {:reply, food, state}
  end

  def handle_call(:robots, _from, %{robots: robots} = state) do
    {:reply, Map.values(robots), state}
  end

  def handle_call({:robot, robot_name}, _from, %{robots: robots} = state) do
    {:reply, Map.fetch(robots, robot_name), state}
  end

  def handle_call(
        {:move_robot, name: robot_name, row: row, column: column},
        _from,
        %{robots: robots, tiles: tiles} = state
      ) do
    robot = Map.fetch!(robots, robot_name)
    {:ok, tile} = Space.get_tile(tiles, row: row, column: column)

    if Space.occupied?(tile, Map.values(robots) -- [robot]) do
      {:reply, {:error, :occupied}, state}
    else
      moved_robot = Robot.move_to(robot, row: row, column: column)
      updated_robots = Map.put(robots, robot_name, moved_robot)
      {:reply, {:ok, moved_robot}, %{state | robots: updated_robots}}
    end
  end

  def handle_call(
        {:orient_robot, name: robot_name, orientation: orientation},
        _from,
        %{robots: robots} = state
      ) do
    robot = Map.fetch!(robots, robot_name)
    oriented_robot = %Robot{robot | orientation: orientation}

    updated_robots = Map.put(robots, robot_name, oriented_robot)
    {:reply, {:ok, oriented_robot}, %{state | robots: updated_robots}}
  end

  def handle_call({:make_food, row, column, food_duration}, _from, state) do
    case Space.get_tile(state.tiles, row: row, column: column) do
      {:ok, tile} ->
        if Tile.has_obstacle?(tile) do
          {:reply, {:error, :invalid}, state}
        else
          updated_state =
            state
            |> erase_food_patch()
            |> do_replace_food_patch(tile, food_duration)
            |> set_ambient_light_around_food()

          {:reply, :ok, updated_state}
        end

      {:error, :invalid} ->
        {:reply, {:error, :invalid}, state}
    end
  end

  # Index = tile's cartesian coordinate
  # A list of rows
  defp init_tiles() do
    tiles_data = Playground.defaults()[:tiles]
    default_ambient = Playground.defaults()[:default_ambient]
    default_color = Playground.defaults()[:default_color]
    row_count = Enum.count(tiles_data)

    Enum.reduce(
      Enum.with_index(tiles_data),
      [],
      fn {row_data, row}, acc ->
        [
          Enum.map(
            Enum.with_index(String.split(row_data, "|")),
            &Tile.from_data(
              row_count - row - 1,
              elem(&1, 1),
              String.graphemes(elem(&1, 0)),
              default_ambient: default_ambient,
              default_color: default_color
            )
          )
          | acc
        ]
      end
    )
  end

  defp reset_food(state) do
    updated_state =
      state
      # Make the current food tile, if any, a normal one
      |> erase_food_patch()
      # Find a new food patch, replacing the previous one if any
      |> replace_food_patch()
      # Change the ambient light of all tiles relative to the food patch (the closer, the brighter)
      |> set_ambient_light_around_food()

    KarmaWorld.broadcast("food_moved", %{})
    updated_state
  end

  defp validate_and_register(
         %{robots: robots, tiles: tiles},
         name: name,
         row: row,
         column: column,
         orientation: orientation
       ) do
    {:ok, tile} = Space.get_tile(tiles, row: row, column: column)

    cond do
      name in Map.keys(robots) ->
        {:error, :name_taken}

      row not in Space.row_range(tiles) ->
        {:error, :invalid_row}

      column not in Space.column_range(tiles) ->
        {:error, :invalid_column}

      Space.occupied?(tile, Map.values(robots)) ->
        {:error, :occupied}

      orientation not in -180..180 ->
        {:error, :invalid_orientation}

      true ->
        :ok
    end
  end

  # Turn the food patch, if any, into ordinary tiles
  defp erase_food_patch(state) do
    if state.food do
      patch_tiles =
        for tile <- patch_tiles(state, state.food.tile) do
          %Tile{
            tile
            | ground_color: defaults()[:default_color],
              ambient_light: defaults()[:default_ambient]
          }
        end

      replace_tiles(state, patch_tiles)
    else
      state
    end
  end

  # Get a patch given a tile at its center. The patch is empty if it can not be.
  defp patch_tiles(state, tile) do
    padding = defaults()[:food_padding]

    for c <- -padding..padding, r <- -padding..padding do
      Space.get_tile(state.tiles, row: tile.row + r, column: tile.column + c)
    end
    |> Enum.reduce_while([], fn answer, acc ->
      case answer do
        {:ok, tile} -> {:cont, [tile | acc]}
        {:error, :invalid} -> {:halt, []}
      end
    end)
  end

  # Replace the current food patch, if any, by a new one somewhere else
  defp replace_food_patch(state) do
    tile = find_next_food_tile(state)
    do_replace_food_patch(state, tile)
  end

  defp do_replace_food_patch(state, food_tile, food_duration \\ nil) do
    duration_range = defaults()[:food_duration_range]
    duration = food_duration || Enum.random(duration_range)
    ambient = ambient_from_duration(duration, duration_range)

    food_patch = patch_tiles(state, food_tile)

    colored_patch_tiles =
      for patch_tile <- food_patch,
          do: %{patch_tile | ground_color: defaults()[:food_color], ambient_light: ambient}

    replace_tiles(
      %{replace_tile(state, food_tile) | food: new_food_tile(food_tile, duration)},
      colored_patch_tiles
    )
  end

  defp new_food_tile(tile, duration),
    do: %{tile: %{row: tile.row, column: tile.column}, duration: duration, total_occupied: 0}

  defp find_next_food_tile(state) do
    old_patch = if state.food, do: patch_tiles(state, state.food.tile), else: []

    state.tiles
    |> List.flatten()
    |> Enum.reject(fn tile ->
      new_patch = patch_tiles(state, tile)

      Enum.empty?(new_patch) or
        patches_overlap?(old_patch, new_patch) or
        Enum.any?(new_patch, &Tile.has_obstacle?/1)
    end)
    |> Enum.random()
  end

  defp patches_overlap?(patch, other_patch) do
    Enum.any?(patch, fn tile ->
      Enum.any?(other_patch, &Tile.same_coordinates?(&1, tile))
    end)
  end

  # The longer the duration, the darker the tile (the lower the ambient light)
  defp ambient_from_duration(duration, min..max) do
    (100 - 100 * (duration - min) / (max - min)) |> round() |> max(10)
  end

  defp replace_tiles(state, new_tiles) do
    Enum.reduce(new_tiles, state, fn tile, acc -> replace_tile(acc, tile) end)
  end

  defp replace_tile(state, new_tile) do
    updated_tiles =
      for row <- state.tiles do
        for tile <- row do
          if Tile.same_coordinates?(tile, new_tile),
            do: new_tile,
            else: tile
        end
      end

    %{state | tiles: updated_tiles}
  end

  # Assumes there is a food patch.
  defp set_ambient_light_around_food(state) do
    food_tile = state.food.tile
    padding = defaults()[:food_padding]
    tile_side_cm = defaults()[:tile_side_cm]
    patch_tiles = patch_tiles(state, state.food.tile)

    updated_tiles =
      for row <- state.tiles do
        for tile <- row do
          if tile in patch_tiles or Tile.has_obstacle?(tile) do
            tile
          else
            distance = Space.distance_to_other_tile(tile, food_tile) - padding * tile_side_cm
            max_distance = defaults()[:max_food_scent_distance_cm]

            ambient =
              if distance > max_distance do
                defaults()[:default_ambient]
              else
                max(round(100 - 100 * distance / max_distance), defaults()[:default_ambient])
              end

            %{tile | ambient_light: ambient}
          end
        end
      end

    %{state | tiles: updated_tiles}
  end

  # Update food if a robot is on it
  defp check_robot_on_food(state) do
    if state.food do
      eating? =
        Enum.any?(patch_tiles(state, state.food.tile), fn tile ->
          Enum.any?(Map.values(state.robots), &Robot.occupies?(&1, tile))
        end)

      food = state.food

      updated_food =
        if eating?,
          do: %{food | total_occupied: food.total_occupied + @check_food_delay_secs},
          else: food

      %{state | food: updated_food}
    else
      state
    end
  end

  # Has the food tile been occupied long enough for the food to be gone?
  defp food_gone?(state),
    do: state.food != nil and state.food.total_occupied > state.food.duration
end
