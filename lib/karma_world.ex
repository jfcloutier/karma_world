defmodule KarmaWorld do
  @moduledoc """
  KarmaWorld keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias KarmaWorld.Playground

  @type device_class :: :sensor | :motor
  @type device_type :: :motor | KarmaWorld.Sensing.Sensor.sensor_type()

  @spec register_device(any(), map()) :: :ok
  def register_device(
        robot_name,
        %{
          device_id: _device_id,
          device_class: _device_class,
          device_type: _device_type,
          properties: _properties
        } = device_data
      ) do
    :ok = Playground.add_device(robot_name, device_data)
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
