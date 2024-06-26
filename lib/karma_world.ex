defmodule KarmaWorld do
  @moduledoc """
  KarmaWorld keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias KarmaWorld.Playground

  require Logger

  @type device_class :: :sensor | :motor
  @type device_type :: :motor | KarmaWorld.Sensing.Sensor.sensor_type()

  @doc """
  Register a robot
  """
  @spec register_robot(any()) :: :ok
  def register_robot(robot_name) do
    placements = Application.get_env(:karma_world, :starting_places)

    :ok =
      Enum.find_value(placements, fn placement ->
        named_placement = placement |> Enum.into(%{}) |> Map.put(:name, robot_name)

        case Playground.place_robot(named_placement) do
          {:ok, _robot} ->
            :ok

          {:error, reason} ->
            Logger.warning("[KarmaWorld] Failed to place robot #{robot_name}: #{inspect(reason)}")
            nil
        end
      end)
  end

  @doc """
  Register a robot's device
  """
  @spec register_device(any(), map()) :: :ok
  def register_device(
        robot_name,
        device_data
      ) do
    :ok = Playground.add_device(robot_name, device_data)
  end

  @doc """
  Read a robot's sensor
  """
  @spec sense(String.t(), String.t(), atom()) :: any()
  def sense(robot_name, device_id, sense) do
    Playground.sense(name: robot_name, sensor_id: device_id, sense: sense)
  end

  @doc """
  Actuate a robot's motor
  """
  @spec actuate(String.t(), String.t(), atom()) :: :ok
  def actuate(robot_name, device_id, action) do
    Playground.actuate(name: robot_name, device_id: device_id, action: action)
  end

  def execute_actions(robot_name) do
    Playground.execute_actions(name: robot_name)
  end

  @doc """
  Broadcast an event
  """
  @spec broadcast(String.t(), map()) :: :ok
  def broadcast(topic, payload),
    do: :ok = Phoenix.PubSub.broadcast(KarmaWorld.PubSub, topic, {String.to_atom(topic), payload})
end
