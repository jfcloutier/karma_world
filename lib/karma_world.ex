defmodule KarmaWorld do
  @moduledoc """
  KarmaWorld keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def register_device(%{
    device_class: _device_class,
    device_type: _device_type,
    connection: _connection,
    properties: _properties
  }) do
    # TODO
    :ok
  end

  def sense(_device_id, _sense) do
    # TODO
    42
  end

  def actuate(_device_id, _action) do
    # TODO
    :ok
  end
end
