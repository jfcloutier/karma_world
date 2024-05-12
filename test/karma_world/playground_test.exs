defmodule Playground.Playground.Test do
  use ExUnit.Case

  alias KarmaWorld.{Playground, Space, Tile, Robot}
  require Logger

  setup_all do
    :ok = Playground.make_food(row: 15, column: 9, food_duration: 2)
    tiles = Playground.tiles()
    default_color = Playground.defaults()[:default_color]
    default_ambient = Playground.defaults()[:default_ambient]
    food_color = Playground.defaults()[:food_color]
    {:ok, food_tile} = Space.get_tile(tiles, row: 15, column: 9)

    {:ok,
     %{
       tiles: tiles,
       food_tile: food_tile,
       tile_defaults: %{color: default_color, food_color: food_color, ambient: default_ambient}
     }}
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

    test "Beacon tile properties", %{tiles: tiles, tile_defaults: tile_defaults} do
      {:ok, tile} = Space.get_tile(tiles, row: 17, column: 9)
      assert tile.beacon_orientation == :south
      assert tile.beacon_channel == 1
      assert tile.obstacle_height == 10
      assert tile.ground_color == tile_defaults.color
      assert tile.ambient_light == tile_defaults.ambient
    end

    test "Food tile properties", %{food_tile: tile, tile_defaults: tile_defaults} do
      assert tile.beacon_orientation == nil
      assert tile.beacon_channel == nil
      assert tile.obstacle_height == 0
      assert tile.ground_color == tile_defaults.food_color
    end

    test "Food ambient gradient", %{food_tile: food_tile, tiles: tiles} do
      {:ok, tile_closest} =
        Space.get_tile(tiles, row: food_tile.row - 1, column: food_tile.column)

      {:ok, tile_closer} = Space.get_tile(tiles, row: food_tile.row - 2, column: food_tile.column)
      {:ok, tile_close} = Space.get_tile(tiles, row: food_tile.row - 3, column: food_tile.column)
      assert tile_closest.ambient_light > tile_closer.ambient_light
      assert tile_closer.ambient_light > tile_close.ambient_light
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

  test "Robot eating the food", %{food_tile: food_tile} do
    assert food().total_occupied == 0

    {:ok, _robot} =
      Playground.place_robot(%{
        name: :andy,
        row: food_tile.row,
        column: food_tile.column,
        orientation: 90
      })

    Process.sleep(3_000)
    %{row: row, column: column} = food().tile
    refute food_tile.row == row and food_tile.column == column
  end

  defp food(), do: :sys.get_state(Playground).food
end
