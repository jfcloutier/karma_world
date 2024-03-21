defmodule KarmaWorld.Actuating.Motor do
  @moduledoc "A robot's motor."

  alias __MODULE__

  defstruct connection: nil,
            # e.g. :motor
            type: nil,
            # direction: -1 if positive speed means backward, 1 if positive speed means forward, 0 if means no motion (at default polarity)
            direction: 0,
            # side: # one of :left, :right or :center
            side: :center,
            # e.g. speed_mode (:rps or :dps), speed (rotation per sec  or degrees per second) and time (run duration in secs)
            controls: %{}

  def from(%{connection: connection, direction: direction, side: side, controls: controls}) do
    %Motor{
      connection: connection,
      direction: direction,
      side: side,
      controls: Map.merge(default_controls(), controls)
    }
  end

  def update_control(motor, control, value) do
    %Motor{motor | controls: Map.put(motor.controls, control, value)}
  end

  def reset_controls(%Motor{} = motor) do
    %Motor{motor | controls: default_controls()}
  end

  def rotations_per_sec(%Motor{controls: controls, direction: direction}) do
    rps_speed = rps_speed(controls)
    rps_speed * direction
  end

  def run_duration(%Motor{controls: controls}) do
    Map.get(controls, :time, 0)
  end

  def run_duration(_motor), do: 0

  ### Private

  defp default_controls() do
    %{time: 0, speed_mode: :rps, speed: 0}
  end

  defp rps_speed(%{speed_mode: :rps, speed: speed}) do
    speed
  end

  defp rps_speed(%{speed_mode: :dps, speed: speed}) do
    speed / 360
  end
end
