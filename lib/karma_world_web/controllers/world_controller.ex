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
    case KarmaWorld.register_robot(robot_name) do
      :ok ->
        render(conn, :registered_body, result: "succeeded")

      {:error, _reason} ->
        conn
        |> put_status(:invalid)
        |> put_view(json: KarmaWorld.ErrorJSON)
        |> render(:"406")
    end
  end

  def register_device(
        conn,
        %{
          "body_name" => robot_name,
          "device_id" => device_id,
          "device_class" => device_class,
          "device_type" => device_type,
          "properties" => properties
        }
      ) do
    result =
      KarmaWorld.register_device(robot_name, %{
        device_id: device_id,
        device_class: device_class,
        device_type: device_type,
        properties: properties
      })

    render(conn, :registered_device, result: result)
  end

  def sense(conn, %{"body_name" => body_name, "device_id" => device_id, "sense" => sense}) do
    value = KarmaWorld.sense(body_name, device_id, sense)
    render(conn, :sensed, sensor: device_id, sense: sense, value: value)
  end

  def set_motor_control(conn, %{"body_name" => body_name, "device_id" => device_id, "control" => control_s, "value" => value_s}) do
    control = String.to_atom(control_s)
    {value, ""} = Float.parse(value_s)
    result = KarmaWorld.set_motor_control(body_name, device_id, control, value)
    render(conn, :set_motor_control, motor: device_id, control: control, value: value, result: result)
  end

  @spec actuate(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def actuate(conn, %{"body_name" => body_name}) do
    result = KarmaWorld.actuate(body_name)
    render(conn, :actuated, result: result)
  end
end
