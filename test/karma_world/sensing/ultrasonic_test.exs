defmodule KarmaWorld.Sensing.Ultrasonic.Test do
  use ExUnit.Case

  alias KarmaWorld.Playground

  require Logger

  setup_all do
    {:ok, %{}}
  end

  setup do
    Playground.clear_robots()
  end

  describe "Sensing distance" do
    test "Distance to edge" do
      Playground.place_robot(
        name: :andy,
        row: 10,
        column: 10,
        orientation: 180,
        sensor_data: [
          %{
            connection: "in4",
            type: :ultrasonic,
            position: :front,
            height_cm: 10,
            aim: 0
          }
        ],
        motor_data: []
      )

      assert {:ok, 100} = Playground.read(name: :andy, sensor_id: "in4", sense: :distance)

      Playground.move_robot(name: :andy, row: 0, column: 0)
      assert {:ok, 2} = Playground.read(name: :andy, sensor_id: "in4", sense: :distance)
    end

    test "Distance to obstacle" do
      Playground.place_robot(
        name: :andy,
        row: 7,
        column: 10,
        orientation: 90,
        sensor_data: [
          %{
            connection: "in4",
            type: :ultrasonic,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: []
      )

      assert {:ok, 30} = Playground.read(name: :andy, sensor_id: "in4", sense: :distance)
    end

    test "Distance to other robot" do
      {:ok, _} = Playground.place_robot(
        name: :andy,
        row: 10,
        column: 10,
        orientation: -135,
        sensor_data: [
          %{
            connection: "in4",
            type: :ultrasonic,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: []
      )

      {:ok, _} = Playground.place_robot(
        name: :karl,
        row: 2,
        column: 1,
        orientation: 90,
        sensor_data: [
          %{
            connection: "in4",
            type: :ultrasonic,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: []
      )

      assert {:ok, 115} = Playground.read(name: :andy, sensor_id: "in4", sense: :distance)

      Playground.move_robot(name: :karl, row: 9, column: 9)
      assert {:ok, 16} = Playground.read(name: :andy, sensor_id: "in4", sense: :distance)
    end
  end
end
