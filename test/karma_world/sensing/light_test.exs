defmodule KarmaWorld.Sensing.Light.Test do
  use ExUnit.Case

  alias KarmaWorld.Sensing.Light
  alias KarmaWorld.Playground

  require Logger

  setup_all do
    :ok = Playground.make_food(row: 15, column: 9, food_duration: 2)
    tiles = Playground.tiles()
    default_color = Playground.defaults()[:default_color]
    default_ambient = Playground.defaults()[:default_ambient]

    sensor_data = %{
      device_id: "light-in2",
      device_class: :sensor,
      device_type: :light,
      position: :front,
      height_cm: 2,
      aim: 0
    }

    {:ok,
     %{
       tiles: tiles,
       tile_defaults: %{color: Light.translate_color(default_color), ambient: default_ambient},
       sensor_data: sensor_data
     }}
  end

  setup do
    Playground.clear_robots()
  end

  describe "Sensing light" do
    test "seeing floor", %{tile_defaults: %{color: default_color}, sensor_data: sensor_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: 0
        })

      Playground.add_device(robot.name, sensor_data)

      assert {:ok, ^default_color} =
               Playground.sense(name: :andy, sensor_id: "light-in2", sense: :color)
    end

    test "seeing food", %{sensor_data: sensor_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 15,
          column: 9,
          orientation: 0
        })

      Playground.add_device(robot.name, sensor_data)
      assert {:ok, :green} = Playground.sense(name: :andy, sensor_id: "light-in2", sense: :color)
    end
  end

  describe "Seeing ambient light because close to food" do
    test "See default ambient light", %{
      tile_defaults: tile_defaults,
      sensor_data: sensor_data
    } do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: 0
        })

      Playground.add_device(robot.name, sensor_data)

      {:ok, sensed_ambient} =
        Playground.sense(name: :andy, sensor_id: "light-in2", sense: :ambient)

      assert sensed_ambient > tile_defaults[:ambient]
    end

    test "Very far from the food", %{sensor_data: sensor_data, tile_defaults: tile_defaults} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 6,
          column: 3,
          orientation: 0
        })

      Playground.add_device(robot.name, sensor_data)

      {:ok, sensed_ambient} =
        Playground.sense(name: :andy, sensor_id: "light-in2", sense: :ambient)

      assert sensed_ambient == tile_defaults[:ambient]
    end
  end
end
