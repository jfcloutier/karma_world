defmodule KarmaWorld.Sensing.Light do
  @moduledoc "Sensing color"

  alias KarmaWorld.Tile
  alias KarmaWorld.Sensing.Sensor

  @behaviour Sensor

  @impl Sensor
  def sense(_robot, _sensor, :color, tile, _tiles, _robots) do
    translate_color(Tile.ground_color(tile))
  end

  def sense(_robot, _sensor, :ambient, tile, _tiles, _robots) do
    Tile.ambient_light(tile)
  end

  def sense(_robot, _sensor, :reflected, tile, _tiles, _robots) do
    Tile.reflected_light(tile)
  end

  def translate_color(number) do
    case number do
      0 -> :unknown
      1 -> :black
      2 -> :blue
      3 -> :green
      4 -> :yellow
      5 -> :red
      6 -> :white
      7 -> :brown
    end
  end
end
