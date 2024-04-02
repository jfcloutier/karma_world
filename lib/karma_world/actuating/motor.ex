defmodule KarmaWorld.Actuating.Motor do
  @moduledoc "A robot's motor."

  require Logger

  @type side :: :center | :left | :right
  @type action :: :spin | :reverse_spin
  @type t :: %__MODULE__{
          # the unique ide of the motor
          id: String.t(),
          type: atom(),
          # The side of the robot the motor is on
          side: side(),
          # Operational constants set when registering the device, e.g. speed_mode (:rps or :dps), speed (rotation per sec  or degrees per second)
          controls: map(),
          # The direction in which the motor is about to run
          # direction: -1 if positive speed means backward, 1 if positive speed means forward, 0 if means no motion (at default polarity)
          direction: integer(),
          # duration in secs over which the motor is about to run
          duration: integer(),
          # the sense-able cumulative rotations (positive or negative) taken by the motor until now
          position: integer(),
          # the sense-able state the motor is currently in
          state: :running | :ramping | :holding | :overloaded,
          actions: [action]
        }

  @default_position :center
  @default_polarity :normal

  defstruct id: nil,
            type: nil,
            side: :center,
            controls: %{},
            direction: 1,
            duration: 0,
            position: 0,
            state: :holding,
            actions: []

  @doc """
  Make a motor from data
  """
  @spec from(map()) :: t()
  def from(%{
        device_id: device_id,
        device_class: :motor,
        device_type: device_type,
        properties: properties
      }) do
    position = Map.get(properties, :position, @default_position)
    controls = extract_controls(properties)

    %__MODULE__{
      id: device_id,
      type: device_type,
      side: position,
      controls: Map.merge(default_controls(), controls)
    }
  end

  # For testing - TODO - GET RID OF IT
  # def from(%{
  #       device_id: device_id,
  #       device_class: :motor,
  #       device_type: device_type,
  #       direction: direction,
  #       side: side,
  #       controls: controls
  #     }) do
  #   %__MODULE__{
  #     id: device_id,
  #     type: device_type,
  #     direction: direction,
  #     side: side,
  #     controls: Map.merge(default_controls(), controls)
  #   }
  # end

  def sense(
        _robot,
        motor,
        sense,
        _robot_tile,
        _tiles,
        _robots
      ) do
    case sense do
      # TODO
      :position -> motor.position
      :state -> :holding
    end
  end

  def actuate(motor, action), do: %{motor | actions: motor.actions ++ [action]}

  # Set duration and direction from pending actions, and reset actions
  # Assumes each spin or reverse spin lasts 1 second.
  def aggregate_actions(motor) do
    spin_count = Enum.count(motor.actions, &(&1 == :spin))
    reverse_spin_count = Enum.count(motor.actions, &(&1 == :reverse_spin))
    bursts = spin_count - reverse_spin_count

    # spin and reverse_spin are inverted if motor polarity is :inversed (not :normal)
    direction =
      if(bursts >= 0, do: 1, else: -1) *
        direction_from_polarity(Map.get(motor.controls, :polarity, @default_polarity))

    duration = abs(bursts) * Map.get(motor.controls, :burst_secs, 1)

    Logger.debug(
      "[KarmaWorld] - Motor #{inspect(motor)} aggregated actions #{inspect(motor.actions)} to #{inspect(%{direction: direction, duration: abs(bursts)})}"
    )

    %{motor | direction: direction, duration: duration, actions: []}
  end

  # Positive for forward, negative for backward
  def rotations_per_sec(%{controls: controls, direction: direction}) do
    rps_speed = rps_speed(controls)
    rps_speed * direction
  end

  def run_completed(motor), do: %{motor | duration: 0, state: :holding}

  ### Private

  defp extract_controls(%{rpm: rpm} = properties) do
    extracted = %{speed_mode: :rps, speed: round(rpm / 60)}

    extracted =
      if Map.has_key?(properties, :burst_secs),
        do: Map.put(extracted, :burst_secs, properties.burst_secs),
        else: extracted

    if Map.has_key?(properties, :polarity),
      do: Map.put(extracted, :polarity, properties.polarity),
      else: extracted
  end

  defp default_controls() do
    %{speed_mode: :rps, speed: 0, burst_secs: 1, polarity: :normal}
  end

  defp rps_speed(%{speed_mode: :rps, speed: speed}) do
    speed
  end

  defp rps_speed(%{speed_mode: :dps, speed: speed}) do
    speed / 360
  end

  defp direction_from_polarity(polarity) do
    case polarity do
      :normal -> 1
      :inversed -> -1
      _other -> 0
    end
  end
end
