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
    <div class="m-4">
      <% "text-orange-900 bg-orange-900 text-orange-950 bg-orange-950 txt-blue-500 bg-blue-500 text-green-500 bg-green-500 text-gray-700 bg-gray-700 text-gray-600 bg-gray-600 text-gray-500 bg-gray-500 text-gray-400 bg-gray-400 textgray-300 bg-gray-300 text-gray-50 bg-gray-50" %>
      <table class="table-fixed">
        <%= for row <- Enum.reverse(@tiles) do %>
          <tr>
            <%= for tile <- row do %>
              <% tile_class = tile_class(tile) %>
              <td class={"#{tile_class} border-2 border-slate-200 w-14 h-14 max-w-14 max-h-14 text-center"}>
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
        first = String.at(tile.robot.name, 0) |> String.upcase()

        rotation = tile.robot.orientation

        png =
          case first do
            "A" ->
              "andy.png"

            "K" ->
              "karla.png"

            _other ->
              "anon.png"
          end

        """
        <div class="group relative w-max">
           <img src=\"images/#{png}\" width=60% style=\"display: block;margin-left: auto; margin-right: auto; rotate: #{rotation}deg\"/>
           <span class="rounded-md bg-gray-200 border-2 border-gray-700 p-2 pointer-events-none absolute -top-12 left-0 w-max opacity-0 transition-opacity group-hover:opacity-100">
              #{Robot.tooltip(tile.robot)}
          </span>
        </div>
        """

      tile.beacon_orientation != nil ->
        rotation =
          case tile.beacon_orientation do
            :north -> 0
            :east -> 90
            :south -> 180
            :west -> -90
          end

        """
        <div class="group relative w-max">
          <img src=\"images/beam.png\" width=60% style=\"display: block;margin-left: auto; margin-right: auto; rotate: #{rotation}deg\"/>
          <span class="rounded-md bg-gray-200 border-2 border-gray-700 p-2 pointer-events-none absolute -top-12 left-0 w-max opacity-0 transition-opacity group-hover:opacity-100">
            Channel #{tile.beacon_channel}
          </span>
        </div>
        """

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
      tile.obstacle_height > 10 -> "orange-950"
      tile.obstacle_height > 0 -> "orange-900"
      tile.ground_color == 2 -> "blue-500"
      tile.ground_color == 3 -> "green-500"
      tile.ambient_light < 15 -> "gray-700"
      tile.ambient_light < 30 -> "gray-600"
      tile.ambient_light < 50 -> "gray-500"
      tile.ambient_light < 70 -> "gray-400"
      tile.ambient_light < 80 -> "gray-300"
      tile.ambient_light <= 100 -> "gray-50"
    end
  end
end
