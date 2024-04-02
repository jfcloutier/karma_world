defmodule KarmaWorldWeb.WorldController do
  @moduledoc """
  Controller for Karma World's API.
  """

  use KarmaWorldWeb, :controller

  # %{"robot_name" => "karl", "device_id" => "touch-in1", "device_class" => "sensor", "device_type" => "touch", "properties" => %{"orientation" => "forward", "position" => "front"}}
  def register_body(
        conn,
        %{"body_name" => robot_name}
      ) do
    :ok = KarmaWorld.register_robot(robot_name)

    render(conn, :registered_body, result: "succeeded")
  end

  def register_device(
        conn,
        %{
          "body_name" => robot_name,
          "device_id" => device_id,
          "device_class" => device_class_s,
          "device_type" => device_type_s,
          "properties" => properties
        }
      ) do
    device_class = String.to_atom(device_class_s)
    device_type = String.to_atom(device_type_s)

    result =
      KarmaWorld.register_device(robot_name, %{
        device_id: device_id,
        device_class: device_class,
        device_type: device_type,
        properties: atomize(properties)
      })

    render(conn, :registered_device, result: result)
  end

  def sense(conn, %{"body_name" => body_name, "device_id" => device_id, "sense" => sense_s}) do
    sense = sense_from_string(sense_s)
    {:ok, value} = KarmaWorld.sense(body_name, device_id, sense)
    render(conn, :sensed, sensor: device_id, sense: sense_s, value: value)
  end

  @spec actuate(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def actuate(conn, %{"body_name" => body_name, "device_id" => device_id, "action" => action_s}) do
    action = String.to_atom(action_s)
    result = KarmaWorld.actuate(body_name, device_id, action)
    render(conn, :actuated, result: result)
  end

  @spec execute_actions(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def execute_actions(conn, %{"body_name" => body_name}) do
    result = KarmaWorld.execute_actions(body_name)
    render(conn, :executed, result: result)
  end

  defp sense_from_string(sense_s) do
    case String.split(sense_s, "_") do
      ["heading", channel_s] ->
        {channel, ""} = Integer.parse(channel_s)
        {:beacon_heading, channel}

      ["distance", channel_s] ->
        {channel, ""} = Integer.parse(channel_s)
        {:beacon_distance, channel}

      ["proximity"] ->
        :proximity
    end
  end

  defp atomize(data) when is_map(data) do
    data
    |> Enum.map(fn {key, val} ->
      {String.to_atom(key), atomize(val)}
    end)
    |> Enum.into(%{})
  end

  defp atomize(data) when is_binary(data), do: String.to_atom(data)
  defp atomize(data), do: data
end
