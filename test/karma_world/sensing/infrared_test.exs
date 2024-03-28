defmodule KarmaWorld.Sensing.Infrared.Test do
  use ExUnit.Case

  alias KarmaWorld.Playground

  require Logger

  setup_all do
    sensor_data = %{
      device_id: "infrared-in3",
      device_class: :sensor,
      device_type: :infrared,
      position: :front,
      height_cm: 10,
      aim: 0
    }

    {:ok, %{sensor_data: sensor_data}}
  end

  setup do
    Playground.clear_robots()
  end

  describe "Sensing beacon" do
    test "Heading to beacon", %{sensor_data: sensor_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 9,
          column: 9,
          orientation: 0
        })

      Playground.add_device(robot.name, sensor_data)

      assert {:ok, 0} =
               Playground.read(
                 name: :andy,
                 sensor_id: "infrared-in3",
                 sense: {:beacon_heading, 1}
               )

      Playground.orient_robot(name: :andy, orientation: 90)

      assert {:ok, -25} =
               Playground.read(
                 name: :andy,
                 sensor_id: "infrared-in3",
                 sense: {:beacon_heading, 1}
               )

      Playground.orient_robot(name: :andy, orientation: -90)

      assert {:ok, 25} =
               Playground.read(
                 name: :andy,
                 sensor_id: "infrared-in3",
                 sense: {:beacon_heading, 1}
               )

      Playground.orient_robot(name: :andy, orientation: 0)
      Playground.move_robot(name: :andy, row: 0, column: 0)

      assert {:ok, 8} =
               Playground.read(
                 name: :andy,
                 sensor_id: "infrared-in3",
                 sense: {:beacon_heading, 1}
               )

      Playground.move_robot(name: :andy, row: 0, column: 19)
      # hidden by obstacle
      assert {:ok, 0} =
               Playground.read(
                 name: :andy,
                 sensor_id: "infrared-in3",
                 sense: {:beacon_heading, 1}
               )

      Playground.move_robot(name: :andy, row: 9, column: 19)

      assert {:ok, -14} =
               Playground.read(
                 name: :andy,
                 sensor_id: "infrared-in3",
                 sense: {:beacon_heading, 1}
               )
    end
  end

  test "Distance to beacon 1", %{sensor_data: sensor_data} do
    {:ok, robot} =
      Playground.place_robot(%{
        name: :andy,
        row: 9,
        column: 9,
        orientation: 0
      })

    Playground.add_device(robot.name, sensor_data)

    # 80 cms is 40% of 200cm
    assert {:ok, 40} =
             Playground.read(name: :andy, sensor_id: "infrared-in3", sense: {:beacon_distance, 1})

    Playground.move_robot(name: :andy, row: 4, column: 16)
    # hidden
    assert {:ok, :unknown} =
             Playground.read(name: :andy, sensor_id: "infrared-in3", sense: {:beacon_distance, 1})

    Playground.move_robot(name: :andy, row: 10, column: 16)
    Playground.orient_robot(name: :andy, orientation: 45)

    assert {:ok, 49} =
             Playground.read(name: :andy, sensor_id: "infrared-in3", sense: {:beacon_distance, 1})

    Playground.orient_robot(name: :andy, orientation: 180)
    # looking away from the beacon
    assert {:ok, :unknown} =
             Playground.read(name: :andy, sensor_id: "infrared-in3", sense: {:beacon_distance, 1})
  end

  test "Distance to beacon 2", %{sensor_data: sensor_data} do
    {:ok, robot} =
      Playground.place_robot(%{
        name: :andy,
        row: 9,
        column: 9,
        orientation: 180
      })

    Playground.add_device(robot.name, sensor_data)

    # 80 cms is 40% of 200cm
    assert {:ok, 46} =
             Playground.read(name: :andy, sensor_id: "infrared-in3", sense: {:beacon_distance, 2})

    Playground.move_robot(name: :andy, row: 11, column: 1)
    # hidden
    assert {:ok, :unknown} =
             Playground.read(name: :andy, sensor_id: "infrared-in3", sense: {:beacon_distance, 2})

    Playground.move_robot(name: :andy, row: 5, column: 6)
    Playground.orient_robot(name: :andy, orientation: 170)

    assert {:ok, 21} =
             Playground.read(name: :andy, sensor_id: "infrared-in3", sense: {:beacon_distance, 2})

    Playground.orient_robot(name: :andy, orientation: 0)
    # looking away from the beacon
    assert {:ok, :unknown} =
             Playground.read(name: :andy, sensor_id: "infrared-in3", sense: {:beacon_distance, 2})
  end
end
