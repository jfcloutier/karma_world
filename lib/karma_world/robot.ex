defmodule KarmaWorld.Robot do
  @moduledoc """
  What is known about a robot
  """

  alias KarmaWorld.{Playground, Space, Tile}
  alias KarmaWorld.Actuating.Motor
  alias KarmaWorld.Sensing.Sensor

  require Logger

  # simulate motion at at most 0.1 sec deltas
  @largest_tick_duration 0.1

  @type t :: %__MODULE__{
          name: String.t(),
          # 0 is N, 90 is E, 180 is S, -90 is W
          orientation: integer(),
          x: float(),
          y: float(),
          sensors: map(),
          motors: map()
        }

  defstruct name: nil,
            orientation: 0,
            x: 0.0,
            y: 0.0,
            sensors: %{},
            motors: %{}

  @doc """
  Make a robot from data
  """
  @spec new(
          name: any(),
          orientation: integer(),
          row: non_neg_integer(),
          column: non_neg_integer()
        ) :: t()
  def new(
        name: name,
        orientation: orientation,
        row: row,
        column: column
      ) do
    %__MODULE__{
      name: name,
      orientation: orientation,
      y: row * 1.0 + 0.5,
      x: column * 1.0 + 0.5
    }
  end

  @doc """
  Add a sensor or motor to a robot
  """
  @spec add_device(t(), map()) :: t()
  def add_device(robot, device_data) do
    case device_data.device_class do
      :sensor -> add_sensor(robot, device_data)
      :motor -> add_motor(robot, device_data)
    end
  end

  @doc """
  Move a robot to a new cartesian coordinate
  """
  @spec move_to(t(), keyword()) :: t()
  def move_to(robot, row: row, column: column) do
    %{robot | y: row * 1.0 + 0.5, x: column * 1.0 + 0.5}
  end

  @doc """
  Whether a robot occupies a tile.
  """
  @spec occupies?(t(), Tile.t() | keyword()) :: boolean()
  def occupies?(robot, %Tile{row: row, column: column}) do
    occupies?(robot, row: row, column: column)
  end

  def occupies?(%{x: x, y: y}, row: row, column: column) do
    floor(y) == row and floor(x) == column
  end

  @doc """
  Extract the location of a robot as cartesian coordinates
  """
  @spec locate(t()) :: Space.coordinates()
  def locate(%{x: x, y: y}) do
    {x, y}
  end

  @doc """
  Whether a robot's state is changed by an actuation
  """
  @spec changed_by?(atom(), atom()) :: boolean()
  def changed_by?(:motor, :run_for), do: true
  def changed_by?(_effector_type, _command), do: false

  @doc """
  Actuate a robot's motor
  """
  @spec actuate(t(), String.t(), atom(), [Tile.t()], [t()]) :: t()
  def actuate(
        robot,
        motor_id,
        action,
        _tiles,
        _robots
      ) do
    motor = Map.get(robot.motors, motor_id)
    updated_motor = Motor.actuate(motor, action)
    %{robot | motors: Map.put(robot.motors, motor_id, updated_motor)}
  end

  def execute_actions(robot, tiles, other_robots) do
    updated_robot =
      robot
      |> aggregate_actions()
      |> run_motors(tiles, other_robots)

    Logger.info(
      "[KarmaWorld] Robot - #{robot.name} moved from {#{robot.x}, #{robot.y}}, orientation #{robot.orientation} to {#{updated_robot.x}, #{updated_robot.y}}, orientation #{updated_robot.orientation}"
    )

    updated_robot
  end

  # run_motors(robot, tiles, robots -- [robot])
  # |> reset_motors()

  @doc """
  Read a robot's sensor
  """
  @spec sense(t(), String.t(), atom(), [Tile.t()], [t()]) :: any()
  def sense(
        %{sensors: sensors, motors: motors} = robot,
        device_id,
        raw_sense,
        tiles,
        other_robots
      ) do
    case Map.get(sensors, device_id) || Map.get(motors, device_id) do
      nil ->
        Logger.warning(
          "[KarmaWorld] Robot - Robot #{robot.name} has no sensor with id #{inspect(device_id)}"
        )

        nil

      sensor ->
        {x, y} = locate(robot)
        {:ok, tile} = Space.get_tile(tiles, {x, y})
        sense = unpack_sense(raw_sense)

        apply(Sensor.module_for(sensor.type), :sense, [
          robot,
          sensor,
          sense,
          tile,
          tiles,
          other_robots
        ])
    end
  end

  def tooltip(robot) do
    "#{robot.name} is at {#{Float.round(robot.x, 1)},#{Float.round(robot.y, 1)}} and turned #{inspect robot.orientation} degrees"
  end

  # Private

  defp add_sensor(robot, device_data) do
    sensor = Sensor.from(device_data)
    %{robot | sensors: Map.put(robot.sensors, sensor.id, sensor)}
  end

  defp add_motor(robot, device_data) do
    motor = Motor.from(device_data)
    %{robot | motors: Map.put(robot.motors, motor.id, motor)}
  end

  defp unpack_sense({sense, channel}) when is_atom(sense), do: {sense, channel}

  defp unpack_sense(raw_sense) do
    case String.split("#{raw_sense}", "/") do
      [sense, channel] -> {String.to_existing_atom(sense), channel}
      _ -> raw_sense
    end
  end

  defp aggregate_actions(robot) do
    updated_motors =
      Enum.map(robot.motors, fn {motor_id, motor} ->
        {motor_id, Motor.aggregate_actions(motor)}
      end)
      |> Enum.into(%{})

    %{robot | motors: updated_motors}
  end

  defp run_motors(
         robot,
         tiles,
         other_robots
       ) do
    motors = Map.values(robot.motors)

    durations =
      Enum.map(motors, & &1.duration)
      |> Enum.filter(&(&1 != 0))

    tick_duration =
      case durations do
        [] -> 0
        _ -> Enum.min(durations) |> min(@largest_tick_duration)
      end

    if tick_duration == 0 do
      Logger.info("[KarmaWorld] Robot - Duration of actuation is 0. Do nothing.")
      robot
    else
      duration = Enum.max(durations)
      Logger.info("[KarmaWorld] Robot - Running motors of #{robot.name} for #{duration} secs")
      ticks = ceil(duration / tick_duration)

      degrees_per_rotation =
        Playground.defaults()[:degrees_per_motor_rotation]

      tiles_per_rotation =
        Playground.defaults()[:tiles_per_motor_rotation]

      left_motors = Enum.filter(motors, &(&1.side == :left))
      right_motors = Enum.filter(motors, &(&1.side == :right))

      result =
        Enum.reduce(
          0..ticks,
          [
            left_motors: left_motors,
            right_motors: right_motors,
            move: %{orientation: robot.orientation, x: robot.x, y: robot.y}
          ],
          fn tick, acc ->
            secs_elapsed = tick * tick_duration
            # running_motors = Enum.reject(motors, &(&1.duration < secs_elapsed))

            activate_motors(
              secs_elapsed,
              tick_duration,
              acc,
              degrees_per_rotation,
              tiles_per_rotation,
              tiles,
              other_robots
            )
          end
        )

      new_orientation = Space.normalize_orientation(floor(result[:move].orientation))
      updated_motors = result[:left_motors] ++ result[:right_motors]
      updated_motors_map = Enum.map(updated_motors, &{&1.id, &1}) |> Enum.into(%{})

      %{
        robot
        | motors: updated_motors_map,
          orientation: new_orientation,
          x: result[:move].x,
          y: result[:move].y
      }
      |> motors_run_completed()
    end
  end

  # TODO - update position status and state status of motors
  defp activate_motors(
         secs_elapsed,
         tick_duration,
         [
           left_motors: left_motors,
           right_motors: right_motors,
           move: %{orientation: orientation, x: x, y: y}
         ],
         degrees_per_rotation,
         tiles_per_rotation,
         tiles,
         other_robots
       ) do
    running_left_motors = Enum.reject(left_motors, &(&1.duration < secs_elapsed))
    running_right_motors = Enum.reject(right_motors, &(&1.duration < secs_elapsed))

    # negative if backward-moving rotations
    left_forward_rotations =
      Enum.map(running_left_motors, &(Motor.rotations_per_sec(&1) * tick_duration)) |> max()

    right_forward_rotations =
      Enum.map(running_right_motors, &(Motor.rotations_per_sec(&1) * tick_duration)) |> max()

    angle =
      new_orientation(
        orientation,
        left_forward_rotations,
        right_forward_rotations,
        degrees_per_rotation
      )

    {new_x, new_y} =
      new_position(
        x,
        y,
        angle,
        left_forward_rotations,
        right_forward_rotations,
        tiles_per_rotation,
        tiles,
        other_robots
      )

    # update the active motors positions by how much {x,y} changed and each motor's direction
    # set active motors state to : stalled if {x,y} did not change but duration  was not zero, else :holding
    delta = {new_x - x, new_y - y}
    updated_left_motors = Enum.map(left_motors, &Motor.update_position_and_state(&1, delta))
    updated_right_motors = Enum.map(right_motors, &Motor.update_position_and_state(&1, delta))

    [
      left_motors: updated_left_motors,
      right_motors: updated_right_motors,
      move: %{orientation: angle, x: new_x, y: new_y}
    ]
  end

  defp new_orientation(
         orientation,
         left_forward_rotations,
         right_forward_rotations,
         degrees_per_rotation
       ) do
    effective_rotations = left_forward_rotations - right_forward_rotations

    delta_orientation = effective_rotations * degrees_per_rotation
    orientation + delta_orientation
  end

  defp new_position(
         x,
         y,
         angle,
         left_forward_rotations,
         right_forward_rotations,
         tiles_per_rotation,
         tiles,
         other_robots
       ) do
    rotations = (left_forward_rotations + right_forward_rotations) / 2
    distance = rotations * tiles_per_rotation
    delta_y = :math.cos(Space.d2r(angle)) * distance
    delta_x = :math.sin(Space.d2r(angle)) * distance
    new_x = x + delta_x
    new_y = y + delta_y

    case Space.get_tile(tiles, {new_x, new_y}) do
      {:error, :invalid} ->
        {x, y}

      {:ok, tile} ->
        if Space.occupied?(tile, other_robots) do
          Logger.info(
            "[KarmaWorld] Robot - Can't move to new position #{inspect({new_x, new_y})}. Tile is occupied"
          )

          {x, y}
        else
          {new_x, new_y}
        end
    end
  end

  defp motors_run_completed(robot) do
    updated_motors =
      robot.motors
      |> Enum.map(fn {motor_id, motor} -> {motor_id, Motor.run_completed(motor)} end)
      |> Enum.into(%{})

    %{robot | motors: updated_motors}
  end

  defp max(list, default \\ 0)
  defp max([], default), do: default
  defp max(list, _default) when is_list(list), do: Enum.max_by(list, &abs/1)
end
