defmodule KarmaWorld.Sensing.Touch.Test do
  use ExUnit.Case

  alias KarmaWorld.Playground

  require Logger

  setup_all do
    tiles = Playground.tiles()
    default_color = Application.get_env(:andy_world, :default_color)
    default_ambient = Application.get_env(:andy_world, :default_ambient)
    {:ok, %{tiles: tiles, tile_defaults: %{color: default_color, ambient: default_ambient}}}
  end

  setup do
    Playground.clear_robots()
  end

  describe "Touching" do
    test "not touching front" do
      Playground.place_robot(
        name: :andy,
        row: 5,
        column: 2,
        orientation: 90,
        sensor_data: [
          %{
            connection: "in1",
            type: :touch,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: []
      )

      assert {:ok, :released} = Playground.read(name: :andy, sensor_id: "in1", sense: :touch)
    end

    test "not touching side" do
      Playground.place_robot(
        name: :andy,
        row: 5,
        column: 2,
        orientation: 90,
        sensor_data: [
          %{
            connection: "in1",
            type: :touch,
            position: :right,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: []
      )

      assert {:ok, :released} = Playground.read(name: :andy, sensor_id: "in1", sense: :touch)
    end

    test "touching front" do
      Playground.place_robot(
        name: :andy,
        row: 5,
        column: 2,
        orientation: 0,
        sensor_data: [
          %{
            connection: "in1",
            type: :touch,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: []
      )

      assert {:ok, :pressed} = Playground.read(name: :andy, sensor_id: "in1", sense: :touch)
    end

    test "touching side" do
      Playground.place_robot(
        name: :andy,
        row: 5,
        column: 2,
        orientation: 90,
        sensor_data: [
          %{
            connection: "in1",
            type: :touch,
            position: :left,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: []
      )

      assert {:ok, :pressed} = Playground.read(name: :andy, sensor_id: "in1", sense: :touch)
    end
  end
end
