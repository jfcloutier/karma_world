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

  def actuated(%{result: result}),
    do: %{result: result}

  def executed(%{result: result}),
    do: %{result: result}
end
