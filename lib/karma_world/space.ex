defmodule KarmaWorld.Space do
  @moduledoc """
  Space sense maker
  """

  alias KarmaWorld.{Playground, Tile, Robot, Sensing.Sensor}
  require Logger

  @type coordinates :: {float(), float()}

  @simulated_step 0.2

  @occlusion_height 10

  @doc """
  Whether a tile is occupied
  """
  @spec occupied?(Tile.t(), [Robot.t()]) :: boolean()
  def occupied?(%Tile{row: row, column: column} = tile, robots) do
    Tile.has_obstacle?(tile) or
      Enum.any?(robots, &Robot.occupies?(&1, row: row, column: column))
  end

  @doc """
  Whether a tile is occluding sensing
  """
  @spec occluding?(Tile.t(), [Robot.t()]) :: boolean()
  def occluding?(%Tile{row: row, column: column} = tile, robots) do
    tile.obstacle_height > @occlusion_height or
      Enum.any?(robots, &Robot.occupies?(&1, row: row, column: column))
  end

  @doc """
  Whether a tile is unavailable to a robot
  """
  @spec unavailable_to?(Tile.t(), Robot.t(), [Robot.t()]) :: boolean()
  def unavailable_to?(
        %Tile{row: row, column: column} = tile,
        %Robot{} = robot,
        robots
      ) do
    not Robot.occupies?(robot, row: row, column: column) and occupied?(tile, robots)
  end

  @doc """
  Get a tile given a robot or a row and column
  """
  @spec get_tile([Tile.t()], Robot.t() | coordinates() | keyword()) ::
          {:ok, Tile.t()} | {:error, :invalid}
  def get_tile(tiles, row: row, column: column) do
    if on_playground?(row, column, tiles) do
      tile =
        tiles
        |> Enum.at(row)
        |> Enum.at(column)

      {:ok, tile}
    else
      {:error, :invalid}
    end
  end

  def get_tile(tiles, %Robot{x: x, y: y}) do
    get_tile(tiles, {x, y})
  end

  def get_tile(tiles, {x, y}) do
    get_tile(tiles, row: floor(y), column: floor(x))
  end

  @doc """
  Get the tile a robot is on
  """
  @spec robot_tile([Tile.t()], Robot.t()) :: {:error, :invalid} | {:ok, Tile.t()}
  def robot_tile(tiles, %Robot{x: x, y: y}) do
    get_tile(tiles, row: floor(y), column: floor(x))
  end

  @doc "Converts an angle so that angle in -180..180"
  @spec normalize_orientation(integer) :: integer()
  def normalize_orientation(angle) do
    orientation = rem(angle, 360)

    cond do
      orientation <= -180 ->
        normalize_orientation(orientation + 360)

      orientation > 180 ->
        normalize_orientation(orientation - 360)

      true ->
        orientation
    end
  end

  @doc "File the tile adjoining another at a cartesian coordinate given an orientation"
  @spec tile_adjoining_at_angle(integer, {float, float}, [Tile.t()]) ::
          {:ok, Tile.t()} | {:error, atom}
  def tile_adjoining_at_angle(angle, {x, y}, tiles) do
    {:ok, %Tile{row: row, column: column}} = get_tile(tiles, {x, y})
    normalized_angle = normalize_orientation(angle)

    {new_row, new_column} =
      cond do
        normalized_angle in -45..45 -> {row + 1, column}
        normalized_angle in 45..135 -> {row, column + 1}
        normalized_angle in 135..180 or normalized_angle in -180..-135 -> {row - 1, column}
        normalized_angle in -135..-45 -> {row, column - 1}
      end

    get_tile(tiles, row: new_row, column: new_column)
  end

  @doc "Find the {x,y} of the closest point of obstruction/occlusion to a coordinate"
  @spec closest_occluded([Tile.t()], Robot.t() | Tile.t() | coordinates, integer(), [
          Robot.t()
        ]) :: {integer(), integer()}
  def closest_occluded(tiles, %Robot{x: x, y: y}, orientation, robots) do
    closest_occluded(tiles, {x, y}, orientation, robots)
  end

  def closest_occluded(tiles, %Tile{row: row, column: column}, orientation, robots) do
    closest_occluded(tiles, {column, row}, orientation, robots)
  end

  def closest_occluded(tiles, {x, y}, orientation, robots) when is_number(x) and is_number(y) do
    # look fifth of a tile further
    step = @simulated_step
    delta_y = :math.cos(d2r(orientation)) * step
    delta_x = :math.sin(d2r(orientation)) * step
    new_x = x + delta_x
    new_y = y + delta_y

    # points to a different tile yet?
    if floor(new_x) != floor(x) or floor(new_y) != floor(y) do
      case get_tile(tiles, {new_x, new_y}) do
        {:ok, tile} ->
          if occluding?(tile, robots) do
            {floor(new_x), floor(new_y)}
          else
            closest_occluded(tiles, {new_x, new_y}, orientation, robots)
          end

        {:error, _reason} ->
          # A tile on the edge is considered obstructed for distance calculation
          {floor(x), floor(y)}
      end
    else
      closest_occluded(tiles, {new_x, new_y}, orientation, robots)
    end
  end

  @doc "Is a tile visible from a given location?"
  @spec tile_visible_to?(Tile.t(), Robot.t(), [Tile.t()], [Robot.t()]) :: boolean()
  def tile_visible_to?(
        %Tile{} = target_tile,
        %Robot{x: x, y: y} = robot,
        tiles,
        robots
      ) do
    tile_visible_from?(target_tile, {x, y}, tiles, robots, robot)
  end

  @doc """
  Find the closest other robot visible to a robot.
  """
  @spec closest_robot_visible_to(Robot.t(), [Tile.t()], [Robot.t()]) ::
          {:error, :not_found} | {:ok, Robot.t()}
  def closest_robot_visible_to(%Robot{x: x, y: y, name: robot_name} = robot, tiles, robots) do
    # Logger.debug("Looking for robot closest to #{robot.name} located at {#{x},#{y}}")
    other_robots = Enum.reject(robots, &(&1.name == robot_name))

    visible_other_robots =
      Enum.filter(
        other_robots,
        fn other_robot ->
          {:ok, tile} = get_tile(tiles, other_robot)

          # Logger.debug("#{other_robot.name} on row #{tile.row} column #{tile.column}")

          visible? =
            tile_visible_from?(
              tile,
              {x, y},
              tiles,
              robots,
              robot
            )

          # Logger.debug("visible? == #{visible?}")
          visible?
        end
      )

    case Enum.sort(
           visible_other_robots,
           &(distance_to_other_robot(robot, &1) <= distance_to_other_robot(robot, &2))
         ) do
      [] ->
        # Logger.debug("Found no robot closest to #{robot.name}")
        {:error, :not_found}

      [closest_robot | _] ->
        # Logger.debug("Robot #{closest_robot.name} is closest to #{robot.name}")
        {:ok, closest_robot}
    end
  end

  @doc """
  Direction from a robot to another robot
  """
  @spec direction_to_other_robot(Sensor.t(), Robot.t(), Robot.t()) :: integer()
  def direction_to_other_robot(sensor, robot, other_robot) do
    sensor_angle = Sensor.absolute_orientation(sensor.aim, robot.orientation)

    angle_perceived(Robot.locate(robot), sensor_angle, Robot.locate(other_robot))
  end

  @doc """
  The distance from a robot to another robot
  """
  @spec distance_to_other_robot(Robot.t(), Robot.t()) :: float()
  def distance_to_other_robot(robot, other_robot) do
    delta_y_squared =
      (other_robot.y - robot.y)
      |> :math.pow(2)

    delta_x_squared =
      (other_robot.x - robot.x)
      |> :math.pow(2)

    distance = :math.sqrt(delta_y_squared + delta_x_squared)
    distance_cm = distance * Playground.defaults()[:tile_side_cm]
    distance_cm
  end

  @doc """
  Distance in cm between two tiles
  """
  @spec distance_to_other_tile(Tile.t(), Tile.t()) :: float()
  def distance_to_other_tile(tile, other) do
    {tile_x, tile_y} = Tile.location(tile)
    {other_x, other_y} = Tile.location(other)

    delta_y_squared =
      (other_y - tile_y)
      |> :math.pow(2)

    delta_x_squared =
      (other_x - tile_x)
      |> :math.pow(2)

    distance = :math.sqrt(delta_y_squared + delta_x_squared)
    distance_cm = distance * Playground.defaults()[:tile_side_cm]
    distance_cm
  end

  @doc """
  How many row of tiles are there
  """
  @spec row_range([Tile.t()]) :: Range.t()
  def row_range(tiles) do
    0..(Enum.count(tiles) - 1)
  end

  @doc """
  How many columns of tiles are there
  """
  @spec column_range([Tile.t()]) :: Range.t()

  def column_range([row | _] = _tiles) do
    0..(Enum.count(row) - 1)
  end

  @doc """
  Is a row and column within the playground
  """
  @spec on_playground?(integer(), integer(), [Tile.t()]) :: boolean()
  def on_playground?(row, column, tiles) do
    row in row_range(tiles) and column in column_range(tiles)
  end

  @doc """
  Find the tile on which a beacon on a given channel sits
  """
  @spec find_beacon_tile([Tile.t()], integer()) :: Tile.t() | nil
  def find_beacon_tile(tiles, channel) do
    Enum.find(List.flatten(tiles), &(&1.beacon_channel == channel))
  end

  @doc """
  The angle to coordinates  perceived by a sensor given its own coordinates and its orientation.
  0 is noon, 90 is 3 o'clock, 180 is 6 o'clock, -90 is 9 o'clock.
  """
  @spec angle_perceived(coordinates(), integer(), coordinates()) :: integer()
  def angle_perceived({from_x, from_y}, sensor_angle, {target_x, target_y}) do
    distance_y = target_y - from_y
    distance_x = target_x - from_x

    angle =
      cond do
        distance_x == 0 and distance_y >= 0 ->
          0

        distance_x == 0 and distance_y < 0 ->
          180

        true ->
          angle_r = :math.atan(abs(distance_y) / abs(distance_x))
          abs_angle = r2d(angle_r) |> round()
          sign_x = sign(distance_x)
          sign_y = sign(distance_y)

          cond do
            sign_x == 1 and sign_y == 1 -> 90 - abs_angle
            sign_x == 1 and sign_y == -1 -> abs_angle + 90
            sign_x == -1 and sign_y == 1 -> abs_angle - 90
            sign_x == -1 and sign_y == -1 -> abs_angle - 180
          end
      end

    normalize_orientation(angle - sensor_angle)
  end

  @doc """
  Convert degress to radial
  """
  @spec d2r(number()) :: float()
  def d2r(d) do
    d * :math.pi() / 180
  end

  @doc """
  Convert radial to degrees
  """
  @spec r2d(number()) :: float()
  def r2d(r) do
    r * 180 / :math.pi()
  end

  ### PRIVATE

  defp tile_visible_from?(
         %Tile{row: target_row, column: target_column} = target_tile,
         {x, y},
         tiles,
         robots,
         # this robot is not an obstacle
         %Robot{} = robot
       ) do
    distance_x =
      case target_column + 0.5 - x do
        zero when zero in [+0.0, -0.0] -> 0.00000000001
        other -> other
      end

    # Logger.info(
    #   "Tile at #{inspect(Tile.location(target_tile))} visible from #{inspect({x, y})} for #{
    #     robot.name
    #   }?"
    # )

    # Logger.debug("distance_x=#{distance_x}")
    distance_y = target_row + 0.5 - y
    # Logger.debug("distance_y=#{distance_y}")
    angle_r = :math.atan(abs(distance_y / distance_x))
    signs = {sign(distance_x), sign(distance_y)}
    # Logger.debug("angle_r=#{angle_r} signs=#{inspect(signs)}")
    tile_visible_from?(target_tile, {x, y}, tiles, robots, robot, angle_r, signs)
  end

  defp tile_visible_from?(
         %Tile{row: target_row, column: target_column} = target_tile,
         {x, y},
         tiles,
         robots,
         # this robot is not an obstacle
         %Robot{} = robot,
         angle_r,
         {sign_x, sign_y} = signs
       ) do
    step = @simulated_step
    # Logger.debug("angle_r=#{angle_r} => #{r2d(angle_r)} degrees")
    delta_x = :math.cos(angle_r) * step * sign_x
    # Logger.debug("delta_x=#{delta_x}")
    delta_y = :math.sin(angle_r) * step * sign_y
    # Logger.debug("delta_y=#{delta_y}")
    new_x = x + delta_x
    new_y = y + delta_y

    # Logger.debug("location={#{new_x},#{new_y}}")

    if floor(new_y) == target_row and floor(new_x) == target_column do
      true
    else
      case get_tile(tiles, {new_x, new_y}) do
        {:ok, tile} ->
          if unavailable_to?(tile, robot, robots) do
            Logger.info(
              "Obstacle at row #{tile.row} column #{tile.column} hides target tile at row #{target_tile.row} column #{target_tile.column}"
            )

            false
          else
            tile_visible_from?(target_tile, {new_x, new_y}, tiles, robots, robot, angle_r, signs)
          end

        {:error, _reason} ->
          Logger.info("Off the board!")
          # we somehow missed the target tile but there was no obstruction
          true
      end
    end
  end

  defp sign(n) when n < 0, do: -1
  defp sign(_n), do: 1
end
