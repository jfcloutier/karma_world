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
          name: String.t(),
          orientation: integer(),
          sensors: map(),
          motors: map(),
          row: non_neg_integer(),
          column: non_neg_integer()
        ) :: t()
  def new(
        name: name,
        orientation: orientation,
        sensors: sensors_data,
        motors: motors_data,
        row: row,
        column: column
      ) do
    sensors = Enum.map(sensors_data, &{&1.connection, Sensor.from(&1)}) |> Enum.into(%{})
    motors = Enum.map(motors_data, &{&1.connection, Motor.from(&1)}) |> Enum.into(%{})

    %__MODULE__{
      name: name,
      orientation: orientation,
      sensors: sensors,
      motors: motors,
      y: row * 1.0 + 0.5,
      x: column * 1.0 + 0.5
    }
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
  Set a motor control of a robot
  """
  @spec set_motor_control(t(), String.t(), any(), any()) :: t()
  def set_motor_control(%{motors: motors} = robot, connection, control, value) do
    motor = Map.fetch!(motors, connection)

    # Logger.debug(
    #   "Setting control #{inspect(control)} of motor #{motor.connection} to #{inspect(value)}"
    # )

    updated_motor = Motor.update_control(motor, control, value)
    %{robot | motors: Map.put(motors, connection, updated_motor)}
  end

  @doc """
  Whether a robot's state is changed by an actuation
  """
  @spec changed_by?(atom(), atom()) :: boolean()
  def changed_by?(:motor, :run_for), do: true
  def changed_by?(_actuator_type, _command), do: false

  @doc """
  Actuate a robot's motor
  """
  @spec actuate(t(), atom(), atom(), map(), [Tile.t()], [t()]) :: t()
  def actuate(
        robot,
        :motor,
        :run_for,
        _params,
        tiles,
        robots
      ) do
    run_motors(robot, tiles, robots -- [robot])
    |> reset_motors()
  end

  def actuate(robot, _actuator_type, _command, _params, _tiles, _robots) do
    # Do nothing for now if not locomotion
    robot
  end

  @doc """
  Read a robot's sensor
  """
  @spec sense(t(), String.t(), atom(), [Tile.t()], [t()]) :: any()
  def sense(%{sensors: sensors} = robot, connection, raw_sense, tiles, robots) do
    case Map.get(sensors, connection) do
      nil ->
        Logger.warning(
          "[KarmaWorld] Robot - Robot #{robot.name} has no sensor with id #{inspect(connection)}"
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
          robots
        ])
    end
  end

  # Private

  defp unpack_sense({sense, channel}) when is_atom(sense), do: {sense, channel}

  defp unpack_sense(raw_sense) do
    case String.split("#{raw_sense}", "/") do
      [sense, channel] -> {String.to_existing_atom(sense), channel}
      _ -> raw_sense
    end
  end

  defp run_motors(
         robot,
         tiles,
         other_robots
       ) do
    motors = Map.values(robot.motors)
    durations = Enum.map(motors, &Motor.run_duration(&1)) |> Enum.filter(&(&1 != 0))

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

      position =
        Enum.reduce(
          0..ticks,
          %{orientation: robot.orientation, x: robot.x, y: robot.y},
          fn tick, acc ->
            secs_elapsed = tick * tick_duration
            running_motors = Enum.reject(motors, &(Motor.run_duration(&1) < secs_elapsed))
            left_motors = Enum.filter(running_motors, &(&1.side == :left))
            right_motors = Enum.filter(running_motors, &(&1.side == :right))

            activate_motors(
              left_motors,
              right_motors,
              tick_duration,
              acc,
              degrees_per_rotation,
              tiles_per_rotation,
              tiles,
              other_robots
            )
          end
        )

      new_orientation = Space.normalize_orientation(floor(position.orientation))

      Logger.info(
        "[KarmaWorld] Robot - #{robot.name} is now at {#{position.x}, #{position.y}} with orientation #{new_orientation}"
      )

      %{robot | orientation: new_orientation, x: position.x, y: position.y}
    end
  end

  defp activate_motors(
         left_motors,
         right_motors,
         tick_duration,
         %{orientation: orientation, x: x, y: y},
         degrees_per_rotation,
         tiles_per_rotation,
         tiles,
         other_robots
       ) do
    # negative if backward-moving rotations
    left_forward_rotations =
      Enum.map(left_motors, &(Motor.rotations_per_sec(&1) * tick_duration)) |> max()

    right_forward_rotations =
      Enum.map(right_motors, &(Motor.rotations_per_sec(&1) * tick_duration)) |> max()

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

    %{orientation: angle, x: new_x, y: new_y}
  end

  defp reset_motors(%{motors: motors} = robot) do
    updated_motors =
      Enum.map(motors, fn {port, motor} -> {port, Motor.reset_controls(motor)} end)
      |> Enum.into(%{})

    %{robot | motors: updated_motors}
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

  defp max(list, default \\ 0)
  defp max([], default), do: default
  defp max(list, _default) when is_list(list), do: Enum.max_by(list, &abs/1)
end
