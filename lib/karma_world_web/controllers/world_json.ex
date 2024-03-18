defmodule KarmaWorldWeb.WorldJSON do
  @moduledoc """
  World JSON view
  """

  def registered_device(%{result: result}) do
    %{registered: result}
  end

  def sensed(%{sensor: id, sense: sense, value: value}),
    do: %{sensor: id, sense: sense, value: value}

  def actuated(%{actuator: id, action: sense, value: value}),
    do: %{actuator: id, action: sense, value: value}
end
