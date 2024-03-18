defmodule KarmaWorldWeb.WorldController do
  @moduledoc """
  Controller for Karma World's API.
  """

  use KarmaWorldWeb, :controller

  # %{"connection" => "in1", "device_class" => "sensor", "device_type" => "touch", "properties" => %{"orientation" => "forward", "position" => "front"}}
  def register_device(
        conn,
        %{
          "device_class" => device_class,
          "device_type" => device_type,
          "connection" => connection,
          "properties" => properties
        }
      ) do
    result = KarmaWorld.register_device(%{
      device_class: device_class,
      device_type: device_type,
      connection: connection,
      properties: properties
    })

    render(conn, :registered_device, result: result)
  end

  def sense(conn, %{"device_id" => device_id, "sense" => sense}) do
    value = KarmaWorld.sense(device_id, sense)
    render(conn, :sensed, sensor: device_id, sense: sense, value: value)
  end

  def actuate(conn, %{"device_id" => device_id, "action" => action}) do
    value = KarmaWorld.actuate(device_id, action)
    render(conn, :actuated, actuator: device_id, action: action, value: value)
  end
end
