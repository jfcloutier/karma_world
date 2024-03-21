defmodule KarmaWorld.Sensing.Infrared.Test do
  use ExUnit.Case

  alias KarmaWorld.Playground

  require Logger

  setup_all do
    {:ok, %{}}
  end

  setup do
    Playground.clear_robots()
  end

  describe "Sensing beacon" do
    test "Heading to beacon" do
      Playground.place_robot(
        name: :andy,
        row: 9,
        column: 9,
        orientation: 0,
        sensor_data: [
          %{
            connection: "in3",
            type: :infrared,
            position: :front,
            height_cm: 10,
            aim: 0
          }
        ],
        motor_data: []
      )

      assert {:ok, 0} =
               Playground.read(name: :andy, sensor_id: "in3", sense: {:beacon_heading, 1})

      Playground.orient_robot(name: :andy, orientation: 90)

      assert {:ok, -25} =
               Playground.read(name: :andy, sensor_id: "in3", sense: {:beacon_heading, 1})

      Playground.orient_robot(name: :andy, orientation: -90)

      assert {:ok, 25} =
               Playground.read(name: :andy, sensor_id: "in3", sense: {:beacon_heading, 1})

      Playground.orient_robot(name: :andy, orientation: 0)
      Playground.move_robot(name: :andy, row: 0, column: 0)

      assert {:ok, 8} =
               Playground.read(name: :andy, sensor_id: "in3", sense: {:beacon_heading, 1})

      Playground.move_robot(name: :andy, row: 0, column: 19)
      # hidden by obstacle
      assert {:ok, 0} =
               Playground.read(name: :andy, sensor_id: "in3", sense: {:beacon_heading, 1})

      Playground.move_robot(name: :andy, row: 9, column: 19)

      assert {:ok, -14} =
               Playground.read(name: :andy, sensor_id: "in3", sense: {:beacon_heading, 1})
    end
  end

  test "Distance to beacon" do
    Playground.place_robot(
      name: :andy,
      row: 9,
      column: 9,
      orientation: 0,
      sensor_data: [
        %{
          connection: "in3",
          type: :infrared,
          position: :front,
          height_cm: 10,
          aim: 0
        }
      ],
      motor_data: []
    )

    # 80 cms is 40% of 200cm
    assert {:ok, 40} =
             Playground.read(name: :andy, sensor_id: "in3", sense: {:beacon_distance, 1})

    Playground.move_robot(name: :andy, row: 4, column: 16)
    # hidden
    assert {:ok, :unknown} =
             Playground.read(name: :andy, sensor_id: "in3", sense: {:beacon_distance, 1})

    Playground.move_robot(name: :andy, row: 10, column: 16)
    Playground.orient_robot(name: :andy, orientation: 45)

    assert {:ok, 49} =
             Playground.read(name: :andy, sensor_id: "in3", sense: {:beacon_distance, 1})

    Playground.orient_robot(name: :andy, orientation: 180)
    # looking away from the beacon
    assert {:ok, :unknown} =
             Playground.read(name: :andy, sensor_id: "in3", sense: {:beacon_distance, 1})
  end
end
