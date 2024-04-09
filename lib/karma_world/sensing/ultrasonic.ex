defmodule KarmaWorld.Sensing.Ultrasonic do
  @moduledoc "Sensing ultrasonic"

  alias KarmaWorld.{Playground, Space, Robot, Sensing.Sensor}

  @behaviour Sensor

  @max_distance_cm 250

  def sense(
        %Robot{x: x, y: y} = robot,
        ultrasonic_sensor,
        :distance,
        _tile,
        tiles,
        robots
      ) do
    tile_side_cm = Playground.defaults()[:tile_side_cm]
    sensor_orientation = Sensor.absolute_orientation(ultrasonic_sensor.aim, robot.orientation)
    {far_x, far_y} = Space.closest_occluded(tiles, robot, sensor_orientation, robots)
    delta_y_sq = :math.pow(far_y - y, 2)
    delta_x_sq = :math.pow(far_x - x, 2)
    distance = :math.sqrt(delta_y_sq + delta_x_sq)

    actual_distance =
      if ultrasonic_sensor.position != :top do
        distance - 0.5
      else
        distance
      end

    # Reduce distance by 0.5 if the sensor is not mounted on top
    round(actual_distance * tile_side_cm) |> min(@max_distance_cm)
  end
end
