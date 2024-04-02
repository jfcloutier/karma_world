defmodule KarmaWorld.Actuating.Motor.Test do
  use ExUnit.Case
  alias KarmaWorld.{Playground, Robot}
  require Logger

  setup_all do
    {:ok,
     %{
       motors_data: [
         %{
           device_id: "motor-outA",
           device_class: :motor,
           device_type: :tacho_motor,
           properties: %{rpm: 60, burst_secs: 0.1, position: :left, polarity: :normal}
         },
         %{
           device_id: "motor-outB",
           device_class: :motor,
           device_type: :motor,
           properties: %{rpm: 60, burst_secs: 0.1, position: :right, polarity: :normal}
         }
       ]
     }}
  end

  setup do
    Playground.clear_robots()
  end

  describe "Moving" do
    test "No motion", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 9,
          column: 9,
          orientation: 0
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      before_location = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      after_location = robot(:andy) |> Robot.locate()
      assert before_location == after_location
    end

    test "Move forward up", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: 0
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      Playground.actuate(name: :andy, device_id: "motor-outA", action: :spin)
      Playground.actuate(name: :andy, device_id: "motor-outB", action: :spin)

      assert robot(:andy).motors["motor-outA"].actions == [:spin]
      assert robot(:andy).motors["motor-outB"].actions == [:spin]

      {before_x, before_y} = robot(:andy) |> Robot.locate()

      Playground.execute_actions(name: :andy)

      assert Enum.empty?(robot(:andy).motors["motor-outA"].actions)
      assert Enum.empty?(robot(:andy).motors["motor-outB"].actions)

      {after_x, after_y} = robot(:andy) |> Robot.locate()

      assert before_x == after_x
      assert after_y > before_y
    end

    test "Move forward up with obstacle", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 5,
          column: 14,
          orientation: 0
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      for _i <- 1..10 do
        Playground.actuate(name: :andy, device_id: "motor-outA", action: :spin)
        Playground.actuate(name: :andy, device_id: "motor-outB", action: :spin)
      end

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert before_x == after_x
      assert floor(after_y) == floor(before_y)
    end

    test "Move forward down", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: 180
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      for _i <- 1..10 do
        Playground.actuate(name: :andy, device_id: "motor-outA", action: :spin)
        Playground.actuate(name: :andy, device_id: "motor-outB", action: :spin)
      end

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert before_x == after_x
      assert after_y < before_y
    end

    test "Move forward to the right", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: 90
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      for _i <- 1..10 do
        Playground.actuate(name: :andy, device_id: "motor-outA", action: :spin)
        Playground.actuate(name: :andy, device_id: "motor-outB", action: :spin)
      end

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert after_x > before_x
      assert after_y == before_y
    end

    test "Move forward to the left", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: -90
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      for _i <- 1..10 do
        Playground.actuate(name: :andy, device_id: "motor-outA", action: :spin)
        Playground.actuate(name: :andy, device_id: "motor-outB", action: :spin)
      end

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert after_x < before_x
      assert after_y == before_y
    end

    test "Move forward up and to the right", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: 45
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      for _i <- 1..10 do
        Playground.actuate(name: :andy, device_id: "motor-outA", action: :spin)
        Playground.actuate(name: :andy, device_id: "motor-outB", action: :spin)
      end

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert after_x > before_x
      assert after_y > before_y
    end

    test "Move forward down and to the left", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: -135
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      for _i <- 1..10 do
        Playground.actuate(name: :andy, device_id: "motor-outA", action: :spin)
        Playground.actuate(name: :andy, device_id: "motor-outB", action: :spin)
      end

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert after_x < before_x
      assert after_y < before_y
    end

    test "Move backward down", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: 0
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      for _i <- 1..10 do
        Playground.actuate(name: :andy, device_id: "motor-outA", action: :reverse_spin)
        Playground.actuate(name: :andy, device_id: "motor-outB", action: :reverse_spin)
      end

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert before_x == after_x
      assert after_y < before_y
    end

    test "Move backward up", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: 180
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      for _i <- 1..10 do
        Playground.actuate(name: :andy, device_id: "motor-outA", action: :reverse_spin)
        Playground.actuate(name: :andy, device_id: "motor-outB", action: :reverse_spin)
      end

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert before_x == after_x
      assert after_y > before_y
    end

    test "Move backward right", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: -90
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      for _i <- 1..10 do
        Playground.actuate(name: :andy, device_id: "motor-outA", action: :reverse_spin)
        Playground.actuate(name: :andy, device_id: "motor-outB", action: :reverse_spin)
      end

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert after_x > before_x
      assert after_y == before_y
    end

    test "Move backward down and to the left", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: 45
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      for _i <- 1..10 do
        Playground.actuate(name: :andy, device_id: "motor-outA", action: :reverse_spin)
        Playground.actuate(name: :andy, device_id: "motor-outB", action: :reverse_spin)
      end

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert after_x < before_x
      assert after_y < before_y
    end
  end

  describe "Turning" do
    test "Pointing up, turning right", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: 0
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      Playground.actuate(name: :andy, device_id: "motor-outA", action: :spin)
      Playground.actuate(name: :andy, device_id: "motor-outB", action: :reverse_spin)

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert after_x == before_x
      assert after_y == before_y
      after_orientation = robot(:andy).orientation
      assert after_orientation > 0
    end

    test "Pointing up, turning left", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: 0
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      Playground.actuate(name: :andy, device_id: "motor-outA", action: :reverse_spin)
      Playground.actuate(name: :andy, device_id: "motor-outB", action: :spin)

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert after_x == before_x
      assert after_y == before_y
      after_orientation = robot(:andy).orientation
      assert after_orientation < 0
    end

    test "Pointing right, turning right", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: 90
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      Playground.actuate(name: :andy, device_id: "motor-outA", action: :spin)
      Playground.actuate(name: :andy, device_id: "motor-outB", action: :reverse_spin)

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert after_x == before_x
      assert after_y == before_y
      after_orientation = robot(:andy).orientation
      assert after_orientation > 0
    end

    test "Pointing down, turning left", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: 180
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      Playground.actuate(name: :andy, device_id: "motor-outA", action: :reverse_spin)
      Playground.actuate(name: :andy, device_id: "motor-outB", action: :spin)

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert after_x == before_x
      assert after_y == before_y
      after_orientation = robot(:andy).orientation
      assert after_orientation < 180
    end

    test "Pointing left, turning right", %{motors_data: motors_data} do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 10,
          column: 10,
          orientation: -90
        })

      for device_data <- motors_data, do: Playground.add_device(robot.name, device_data)

      Playground.actuate(name: :andy, device_id: "motor-outA", action: :spin)
      Playground.actuate(name: :andy, device_id: "motor-outB", action: :reverse_spin)

      {before_x, before_y} = robot(:andy) |> Robot.locate()
      Playground.execute_actions(name: :andy)
      {after_x, after_y} = robot(:andy) |> Robot.locate()
      assert after_x == before_x
      assert after_y == before_y
      after_orientation = robot(:andy).orientation
      assert after_orientation > -90
    end
  end

  defp robot(name) do
    {:ok, robot} = Playground.robot(name)
    robot
  end
end
