defmodule KarmaWorld.Tile do
  @moduledoc """
  A tile in the playground
  """

  alias KarmaWorld.Space

  require Logger

  @type orientation :: :north | :south | :east | :west

  @type t :: %__MODULE__{
          row: non_neg_integer(),
          column: non_neg_integer(),
          obstacle_height: non_neg_integer(),
          beacon_orientation: orientation(),
          ground_color: non_neg_integer(),
          ambient_light: non_neg_integer()
        }

  defstruct row: nil,
            column: nil,
            obstacle_height: 0,
            beacon_channel: nil,
            beacon_orientation: nil,
            ground_color: nil,
            ambient_light: nil

  @doc """
  Make a tile from data
  """
  # "<obstacle height * 10><beacon orientation><color><ambient * 10>|...."
  # _ = default, otherwise: obstacle in 0..9,  color in 0..7, ambient in 0..9, beacon_orientation in [N, S, E, W]
  @spec from_data(non_neg_integer(), non_neg_integer(), [String.t()], keyword()) :: t()
  def from_data(
        row,
        column,
        [height_s, beacon_s],
        default_ambient: default_ambient,
        default_color: default_color
      ) do
    {channel, orientation} = convert_beacon(beacon_s)

    %__MODULE__{
      row: row,
      column: column,
      obstacle_height: convert_height(height_s),
      beacon_channel: channel,
      beacon_orientation: orientation,
      ground_color: default_color,
      ambient_light: default_ambient
    }
  end

  @doc """
  Do two tiles have the same coordinates?
  """
  @spec same_coordinates?(t(), t()) :: boolean()
  def same_coordinates?(tile, other), do: {tile.row, tile.column} == {other.row, other.column}

  @doc """
  Is there an obstacle on the tile?
  """
  @spec has_obstacle?(t()) :: boolean()
  def has_obstacle?(tile) do
    tile.obstacle_height > 0 or tile.beacon_orientation != nil
  end

  @doc """
  The ground color of the tile
  """
  @spec ground_color(t()) :: non_neg_integer()
  def ground_color(%{ground_color: ground_color}), do: ground_color

  @doc """
  The ambient light of the tile
  """
  @spec ambient_light(t()) :: non_neg_integer()
  def ambient_light(%{ambient_light: ambient_light}), do: ambient_light

  @doc """
  The reflected light of the tile
  """
  @spec reflected_light(t()) :: non_neg_integer()
  def reflected_light(_tile) do
    Logger.warning("[KarmaWorld] Tile - Tile reflected light not implemented yet")
    0
  end

  @doc """
  The coordinates of the center of the tile
  """
  @spec location(t()) :: Space.coordinates()
  def location(%{row: row, column: column}) do
    {column + 0.5, row + 0.5}
  end

  ## Private

  defp convert_height("_"), do: 0

  defp convert_height(height_s) do
    {height, ""} = Integer.parse(height_s)
    height * 10
  end

  defp convert_beacon("_"), do: {nil, nil}

  defp convert_beacon(beacon_s) when beacon_s in ~w(N S E W n s e w) do
    case beacon_s do
      "N" -> {1, :north}
      "S" -> {1, :south}
      "E" -> {1, :east}
      "W" -> {1, :west}
      "n" -> {2, :north}
      "s" -> {2, :south}
      "e" -> {2, :east}
      "w" -> {2, :west}
    end
  end
end
