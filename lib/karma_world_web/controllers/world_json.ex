defmodule KarmaWorldWeb.WorldJSON do
  @moduledoc """
  World JSON view
  """

  def registered_device(%{result: result}) do
    %{registered_device: result}
  end

  def registered_body(%{result: result}) do
    %{registered_body: result}
  end

  def sensed(%{sensor: id, sense: sense, value: value}),
    do: %{sensor: id, sense: sense, value: value}

  def set_motor_control(motor: device_id, control: control, value: value, result: result),
    do: %{motor: device_id, control: control, value: value, result: result}

  def actuated(%{result: result}),
    do: %{result: result}
end
