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
    sense = String.to_atom(sense_s)
    {:ok, value} = KarmaWorld.sense(body_name, device_id, sense)
    render(conn, :sensed, sensor: device_id, sense: sense, value: value)
  end

  def set_motor_control(conn, %{
        "body_name" => body_name,
        "device_id" => device_id,
        "control" => control_s,
        "value" => value_s
      }) do
    control = String.to_atom(control_s)
    {value, ""} = Float.parse(value_s)
    result = KarmaWorld.set_motor_control(body_name, device_id, control, value)

    render(conn, :set_motor_control,
      motor: device_id,
      control: control,
      value: value,
      result: result
    )
  end

  @spec actuate(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def actuate(conn, %{"body_name" => body_name}) do
    result = KarmaWorld.actuate(body_name)
    render(conn, :actuated, result: result)
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
