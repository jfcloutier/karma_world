defmodule KarmaWorld.Sensing.Infrared do
  @moduledoc """
  Sensing infrared beacon.
  Assumes at most one beacon set to some channel
  """

  alias KarmaWorld.{Playground, Space, Tile, Sensing.Sensor, Robot}
  require Logger

  @behaviour Sensor

  @max_distance_cm 70

  # -25 to 25 (-90 degrees to 90 degrees, 0 if undetected)
  @impl Sensor
  def sense(%Robot{x: x, y: y} = robot, infrared_sensor, :proximity, _tile, tiles, robots) do
    tile_side_cm = Playground.defaults()[:tile_side_cm]
    sensor_orientation = Sensor.absolute_orientation(infrared_sensor.aim, robot.orientation)
    {far_x, far_y} = Space.closest_occluded(tiles, robot, sensor_orientation, robots)
    delta_y_sq = :math.pow(far_y - y, 2)
    delta_x_sq = :math.pow(far_x - x, 2)
    distance = :math.sqrt(delta_y_sq + delta_x_sq)

    actual_distance =
      if infrared_sensor.position != :top do
        distance - 0.5
      else
        distance
      end

    # Reduce distance by 0.5 if the sensor is not mounted on top
    round(actual_distance * tile_side_cm) |> min(@max_distance_cm)
  end

  def sense(robot, infrared_sensor, {:beacon_heading, channel}, _robot_tile, tiles, robots) do
    case Space.find_beacon_tile(tiles, channel) do
      nil ->
        0

      %Tile{} = beacon_tile ->
        if beacon_in_front?(
             beacon_tile,
             robot,
             tiles
           ) and Space.tile_visible_to?(beacon_tile, robot, tiles, robots) do
          sensor_angle = Sensor.absolute_orientation(infrared_sensor.aim, robot.orientation)
          # angle relative to where the sensor is pointing.
          # 0 is right in front, 90 is 9 o'clock, 180 is 3 o'clock
          angle_perceived =
            Space.angle_perceived(
              Robot.locate(robot),
              sensor_angle,
              Tile.location(beacon_tile)
            )

          if abs(angle_perceived) <= 90, do: round(25 * angle_perceived / 90), else: 0
        else
          0
        end
    end
  end

  # 0 to 100 (percent, where 100% = 200cm), or -:unknown if undetected
  def sense(
        robot,
        infrared_sensor,
        {:beacon_distance, channel},
        _robot_tile,
        tiles,
        robots
      ) do
    case Space.find_beacon_tile(tiles, channel) do
      nil ->
        :unknown

      %Tile{} = beacon_tile ->
        if beacon_in_front?(
             beacon_tile,
             robot,
             tiles
           ) and Space.tile_visible_to?(beacon_tile, robot, tiles, robots) do
          sensor_angle = Sensor.absolute_orientation(infrared_sensor.aim, robot.orientation)
          {beacon_x, beacon_y} = beacon_location = Tile.location(beacon_tile)

          angle_perceived =
            Space.angle_perceived(
              Robot.locate(robot),
              sensor_angle,
              beacon_location
            )

          if abs(angle_perceived) <= 90 do
            delta_y_squared =
              (beacon_y - robot.y)
              |> :math.pow(2)

            delta_x_squared =
              (beacon_x - robot.x)
              |> :math.pow(2)

            proximity = :math.sqrt(delta_y_squared + delta_x_squared)

            proximity_cm =
              (proximity * Playground.defaults()[:tile_side_cm])
              |> min(200)

            # Convert to percent of 200 cm
            (proximity_cm * 0.5)
            |> round
          else
            :unknown
          end
        else
          :unknown
        end
    end
  end

  # Private

  defp beacon_in_front?(
         %Tile{beacon_orientation: beacon_orientation, row: beacon_row, column: beacon_column},
         %Robot{} = robot,
         tiles
       ) do
    {:ok, %Tile{row: robot_row, column: robot_column}} = Space.get_tile(tiles, robot)

    case beacon_orientation do
      :south ->
        robot_row < beacon_row

      :north ->
        robot_row > beacon_row

      :east ->
        robot_column > beacon_column

      :west ->
        robot_column < beacon_column
    end
  end
end
