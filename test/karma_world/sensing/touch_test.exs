defmodule KarmaWorld.Sensing.Touch.Test do
  use ExUnit.Case

  alias KarmaWorld.Playground

  require Logger

  setup_all do
    tiles = Playground.tiles()
    default_color = Application.get_env(:andy_world, :default_color)
    default_ambient = Application.get_env(:andy_world, :default_ambient)

    sensor_data = %{
      device_id: "touch-in1",
      device_class: :sensor,
      device_type: :touch,
      position: :front,
      height_cm: 2,
      aim: 0
    }

    {:ok,
     %{
       tiles: tiles,
       tile_defaults: %{color: default_color, ambient: default_ambient},
       sensor_data: sensor_data
     }}
  end

  setup do
    Playground.clear_robots()
  end

  describe "Touching" do
    test "not touching front", %{sensor_data: sensor_data} do
      {:ok, robot} =
        Playground.place_robot(
          name: :andy,
          row: 5,
          column: 2,
          orientation: 90
        )

      Playground.add_device(robot.name, sensor_data)

      assert {:ok, :released} =
               Playground.read(name: :andy, sensor_id: "touch-in1", sense: :touch)
    end

    test "not touching side", %{sensor_data: sensor_data} do
      {:ok, robot} =
        Playground.place_robot(
          name: :andy,
          row: 5,
          column: 2,
          orientation: 90
        )

      Playground.add_device(robot.name, sensor_data)

      assert {:ok, :released} =
               Playground.read(name: :andy, sensor_id: "touch-in1", sense: :touch)
    end

    test "touching front", %{sensor_data: sensor_data} do
      {:ok, robot} =
        Playground.place_robot(
          name: :andy,
          row: 5,
          column: 2,
          orientation: 0
        )

      Playground.add_device(robot.name, sensor_data)

      assert {:ok, :pressed} = Playground.read(name: :andy, sensor_id: "touch-in1", sense: :touch)
    end

    test "touching side", %{sensor_data: sensor_data} do
      {:ok, robot} =
        Playground.place_robot(
          name: :andy,
          row: 5,
          column: 2,
          orientation: 90
        )

      Playground.add_device(robot.name, %{sensor_data | position: :left})

      assert {:ok, :pressed} = Playground.read(name: :andy, sensor_id: "touch-in1", sense: :touch)
    end
  end
end
