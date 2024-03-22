defmodule Playground.Playground.Test do
  use ExUnit.Case

  alias KarmaWorld.{Playground, Space, Tile, Robot}
  require Logger

  setup_all do
    tiles = Playground.tiles()
    default_color = Playground.defaults()[:default_color]
    default_ambient = Playground.defaults()[:default_ambient]
    {:ok, %{tiles: tiles, tile_defaults: %{color: default_color, ambient: default_ambient}}}
  end

  setup do
    Playground.clear_robots()
  end

  describe "Tiles" do
    test "Tile ordering", %{tiles: tiles} do
      [[first_tile | _] | _] = tiles
      assert first_tile.row == 0
      assert first_tile.column == 0
    end

    test "Tile properties", %{tiles: tiles, tile_defaults: tile_defaults} do
      {:ok, tile} = Space.get_tile(tiles, row: 17, column: 9)
      assert tile.beacon_orientation == :south
      assert tile.obstacle_height == 10
      assert tile.ground_color == tile_defaults.color
      assert tile.ambient_light == tile_defaults.ambient * 10
    end

    test "Tile occupancy", %{tiles: tiles} do
      {:ok, tile} = Space.get_tile(tiles, row: 5, column: 6)
      robots = Playground.robots()
      assert false == Tile.has_obstacle?(tile)
      assert false == Space.occupied?(tile, robots)
    end
  end

  describe "Placing and moving robots" do
    test "Placing a robot", %{tiles: tiles} do
      {:ok, _robot} =
        GenServer.call(
          Playground,
          {:place_robot, name: :andy, row: 5, column: 6, orientation: 90}
        )

      robots = Playground.robots()
      {:ok, andy} = Playground.robot(:andy)
      assert andy.name == :andy
      assert andy.x == 6.5
      assert andy.y == 5.5
      {:ok, tile} = Space.get_tile(tiles, {andy.x, andy.y})
      assert true == Space.occupied?(tile, robots)
    end

    test "Moving a robot" do
      {:ok, robot} =
        Playground.place_robot(%{
          name: :andy,
          row: 5,
          column: 6,
          orientation: 90
        })

      assert robot.name == :andy

      {:ok, robot} = Playground.move_robot(name: :andy, row: 0, column: 9)

      {:ok, andy_robot} = Playground.robot(:andy)
      assert andy_robot == robot
      assert {9.5, 0.5} == Robot.locate(robot)
    end
  end
end
