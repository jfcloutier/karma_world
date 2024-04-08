defmodule KarmaWorldWeb.PlaygroundLive do
  use Phoenix.LiveView

  alias KarmaWorld.{Playground, Robot}
  alias Phoenix.HTML

  require Logger

  @topics ~w(robot_placed robot_actions_executed)
  @listening ~w(robot_placed robot_actions_executed)a

  def mount(_params, _seesion, socket) do
    if connected?(socket), do: subscribe()
    {:ok, assign(socket, tiles: tiles())}
  end

  def render(assigns) do
    ~H"""
    <div>
      <% "text-orange-800 bg-orange-800 txt-blue-500 bg-blue-500 text-green-500 bg-green-500 text-gray-900 bg-gray-900 text-gray-800 bg-gray-800 text-gray-700 bg-gray-700 text-gray-600 bg-gray-600 textgray-400 bg-gray-400 text-gray-200 bg-gray-200text-gray-50 bg-gray-50" %>
       <table class="table-fixed">
        <%= for row <- Enum.reverse(@tiles) do %>
          <tr>
            <%= for tile <- row do %>
              <% tile_class = tile_class(tile) %>
              <td class={"#{tile_class} border-2 border-slate-200 w-10 h-10 text-center"}>
                <%= HTML.raw(tile_content(tile)) %>
              </td>
            <% end %>
          </tr>
        <% end %>
      </table>
    </div>
    """
  end

  def handle_info({topic, _payload}, socket)
      when topic in @listening do
    {:noreply, assign(socket, tiles: tiles())}
  end

  def handle_info(info, socket) do
    Logger.debug("#{__MODULE__} NOT HANDLING #{inspect(info)}}")

    {:noreply, socket}
  end

  ## Private

  defp tile_class(tile) do
    color = tile_color(tile)

    text_color =
      cond do
        tile.robot != nil ->
          if tile.ambient_light <= 60,
            do: "font-bold text-gray-50",
            else: "font-bold text-gray-900"

        tile.beacon_orientation != nil ->
          "font-bold text-gray-900"

        true ->
          "text-#{color}"
      end

    bg_color = "bg-#{color}"
    tile_class = text_color <> " " <> bg_color
    tile_class
  end

  defp tile_content(tile) do

    cond do
      tile.robot != nil ->
        # Use first letter of name, uppercased
        String.at(tile.robot.name, 0) |> String.upcase()

      tile.beacon_orientation != nil ->
        case tile.beacon_orientation do
          :north -> "&uarr;"
          :east -> "&rarr;"
          :south -> "&darr;"
          :west -> "&larr;"
        end

      true ->
        ""
    end
  end

  defp subscribe() do
    @topics
    |> Enum.each(&Phoenix.PubSub.subscribe(KarmaWorld.PubSub, &1))
  end

  defp tiles() do
    robots = Playground.robots()

    for row <- Playground.tiles() do
      for tile <- row do
        tile_map = Map.from_struct(tile)

        case Enum.find(robots, &Robot.occupies?(&1, tile)) do
          nil ->
            Map.put(tile_map, :robot, nil)

          robot ->
            Map.put(tile_map, :robot, %{
              name: "#{robot.name}",
              x: robot.x,
              y: robot.y,
              orientation: robot.orientation
            })
        end
      end
    end
  end

  defp tile_color(tile) do
    cond do
      tile.obstacle_height > 0 -> "orange-800"
      tile.ground_color == 2 -> "blue-500"
      tile.ground_color == 3 -> "green-500"
      tile.ambient_light <= 10 -> "gray-900"
      tile.ambient_light <= 20 -> "gray-800"
      tile.ambient_light <= 40 -> "gray-700"
      tile.ambient_light <= 60 -> "gray-600"
      tile.ambient_light < 80 -> "gray-400"
      tile.ambient_light < 90 -> "gray-200"
      tile.ambient_light <= 100 -> "gray-50"
    end
  end

end
