defmodule KarmaWorld.Tile.Test do
  use ExUnit.Case

  alias KarmaWorld.{Playground, Tile}

  describe "Tile from data" do
    test "Beacon tile" do
      row_data = "1S__"
      graphemes = String.graphemes(row_data)
      default_ambient = Playground.defaults()[:default_ambient]
      default_color = Playground.defaults()[:default_color]

      tile =
        Tile.from_data(0, 0, graphemes,
          default_ambient: default_ambient,
          default_color: default_color
        )

      assert tile.obstacle_height == 10
      assert tile.beacon_channel == 1
      assert tile.beacon_orientation == :south
      assert tile.ground_color == 7
      assert tile.ambient_light == 100
    end

    test "Dark tile" do
      row_data = "___1"
      graphemes = String.graphemes(row_data)
      default_ambient = Playground.defaults()[:default_ambient]
      default_color = Playground.defaults()[:default_color]

      tile =
        Tile.from_data(0, 0, graphemes,
          default_ambient: default_ambient,
          default_color: default_color
        )

      assert tile.obstacle_height == 0
      assert tile.beacon_channel == nil
      assert tile.beacon_orientation == nil
      assert tile.ground_color == 7
      assert tile.ambient_light == 10
    end

    test "Obstacle tile" do
      row_data = "3___"
      graphemes = String.graphemes(row_data)
      default_ambient = Playground.defaults()[:default_ambient]
      default_color = Playground.defaults()[:default_color]

      tile =
        Tile.from_data(0, 0, graphemes,
          default_ambient: default_ambient,
          default_color: default_color
        )

      assert tile.obstacle_height == 30
      assert tile.beacon_channel == nil
      assert tile.beacon_orientation == nil
      assert tile.ground_color == 7
      assert tile.ambient_light == 100
    end

    test "Color tile" do
      row_data = "__21"
      graphemes = String.graphemes(row_data)
      default_ambient = Playground.defaults()[:default_ambient]
      default_color = Playground.defaults()[:default_color]

      tile =
        Tile.from_data(0, 0, graphemes,
          default_ambient: default_ambient,
          default_color: default_color
        )

      assert tile.obstacle_height == 0
      assert tile.beacon_channel == nil
      assert tile.beacon_orientation == nil
      assert tile.ground_color == 2
      assert tile.ambient_light == 10
    end
  end
end
