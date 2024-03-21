defmodule KarmaWorld do
  @moduledoc """
  KarmaWorld keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @type device_class :: :sensor | :motor
  @type device_type :: :motor | KarmaWorld.Sensing.Sensor.sensor_type()

  @spec register_device(%{
          :connection => String.t(),
          :device_class => device_class(),
          :device_type => device_type(),
          :properties => map()
        }) :: :ok
  def register_device(%{
        device_class: _device_class,
        device_type: _device_type,
        connection: _connection,
        properties: _properties
      }) do
    # TODO
    :ok
  end

  @doc """
  Read a sensor
  """
  @spec sense(String.t(), String.t()) :: any()
  def sense(_device_id, _sense) do
    # TODO
    42
  end

  @doc """
  Actuate a motor
  """
  @spec actuate(String.t(), String.t()) :: :ok
  def actuate(_device_id, _action) do
    # TODO
    :ok
  end

  @doc """
  Broadcast an event
  """
  @spec broadcast(String.t(), map()) :: :ok
  def broadcast(topic, payload),
    do: :ok = Phoenix.PubSub.broadcast(KarmaWorld.PubSub, topic, {String.to_atom(topic), payload})
end
