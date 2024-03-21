defmodule KarmaWorld.Playground do
  @moduledoc """
  Where the robots play.
  A square grid of equilateral tiles arranged in rows, with row 0 "down" and column 0 "left".any()
  North is up at 270 degrees. East is right at 0 degrees.
  """

  use GenServer

  alias KarmaWorld.{Playground, Space, Tile, Robot}
  require Logger

  @type t :: %__MODULE__{tiles: [Tile.t()], robots: map()}

  defstruct tiles: [],
            robots: %{}

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
    {:ok, %__MODULE__{tiles: init_tiles()}}
  end

  @doc """
  Place a robot in the playground
  """
  @spec place_robot(keyword()) :: {:ok, Robot.t()} | {:error, atom()}
  def place_robot(
        name: name,
        row: row,
        column: column,
        orientation: orientation,
        sensor_data: sensors_data,
        motor_data: motors_data
      ),
      do:
        GenServer.call(
          __MODULE__,
          {:place_robot,
           name: name,
           row: row,
           column: column,
           orientation: orientation,
           sensor_data: sensors_data,
           motor_data: motors_data}
        )

  # Test support
  @doc false
  @spec tiles() :: [Tile.t()]
  def tiles(), do: GenServer.call(__MODULE__, :tiles)

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
  @spec set_motor_control(keyword()) :: :ok
  def set_motor_control(name: robot_name, connection: connection, control: control, value: value),
    do: GenServer.call(__MODULE__, {:set_motor_control, robot_name, connection, control, value})

  # Test support
  @doc false
  @spec actuate(keyword()) :: :ok
  def actuate(name: robot_name, actuator_type: actuator_type, command: command),
    do: GenServer.call(__MODULE__, {:actuate, robot_name, actuator_type, command})

  # Test support
  @doc false
  @spec read(keyword()) :: any()
  def read(name: robot_name, sensor_id: sensor_id, sense: sense),
    do: GenServer.call(__MODULE__, {:read, robot_name, sensor_id, sense})

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

  @impl GenServer
  # A robot is placed on the playground
  def handle_call(
        {:place_robot,
         name: name,
         row: row,
         column: column,
         orientation: orientation,
         sensor_data: sensors_data,
         motor_data: motors_data},
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
            sensors: sensors_data,
            motors: motors_data,
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
        {:read, robot_name, sensor_id, sense},
        from,
        %{robots: robots, tiles: tiles} = state
      ) do
    spawn_link(fn ->
      robot = Map.fetch!(robots, robot_name)
      value = Robot.sense(robot, sensor_id, sense, tiles, Map.values(robots))

      Logger.info(
        "[KarmaWorld] Playground - Read #{robot_name}: #{inspect(sensor_id)} #{inspect(sense)} = #{inspect(value)}"
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

  # A motor control is set
  def handle_call(
        {:set_motor_control, robot_name, motor_id, control, value},
        _from,
        %{robots: robots, tiles: tiles} = state
      ) do
    Logger.info(
      "[KarmaWorld] Playground - Set the #{control} of #{robot_name}'s motor #{motor_id} to #{inspect(value)}"
    )

    robot = Map.fetch!(robots, robot_name)
    updated_robot = Robot.set_motor_control(robot, motor_id, control, value)

    KarmaWorld.broadcast("robot_controlled", %{
      robot: updated_robot,
      motor_id: motor_id,
      control: control,
      value: value
    })

    {
      :reply,
      :ok,
      %{state | tiles: tiles, robots: Map.put(robots, robot.name, updated_robot)}
    }
  end

  # Run a robot's motors
  def handle_call(
        {:actuate, robot_name, actuator_type, command},
        _from,
        %{robots: robots, tiles: tiles} = state
      ) do
    robot = Map.fetch!(robots, robot_name)

    updated_robot =
      if Robot.changed_by?(actuator_type, command) do
        Logger.info(
          "[KarmaWorld] Playground - Actuate #{robot.name}: #{inspect(command)} #{inspect(actuator_type)}"
        )

        actuated_robot =
          Robot.actuate(robot, actuator_type, command, tiles, Map.values(robots))

        actuated_robot
      else
        robot
      end

    KarmaWorld.broadcast("robot_actuated", %{
      robot: updated_robot,
      actuator_type: actuator_type,
      command: command
    })

    {:reply, :ok, %{state | robots: Map.put(robots, robot.name, updated_robot)}}
  end

  ### TEST AND LIVE VIEW SUPPORT

  def handle_call(:tiles, _from, %{tiles: tiles} = state) do
    {:reply, tiles, state}
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
end
