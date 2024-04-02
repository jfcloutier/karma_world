defmodule KarmaWorld.Sensing.Sensor do
  @moduledoc """
  Data about a sensor
  """

  alias KarmaWorld.Sensing.{Light, Infrared, Touch, Ultrasonic}
  alias KarmaWorld.Actuating. Motor
  alias KarmaWorld.{Robot, Space, Tile}

  @type position :: :left | :right | :top | :front | :back
  @type sensor_type :: :infrared | :light | :touch | :ultrasonic
  @type t :: %__MODULE__{
          id: String.t(),
          type: atom(),
          # where the sensor is positioned on the robot, one of :left, :right, :top, :front, :back
          position: position(),
          # how high is the sensor riding on the robot
          height_cm: integer(),
          # which way is the sensor pointing, # an angle between -180 and 180
          aim: integer()
        }

  @default_aim :forward
  @default_position :front
  @default_height_cm 10

  defstruct id: nil,
            type: nil,
            position: nil,
            height_cm: nil,
            aim: nil

  @doc """
  Read a robot's sensor
  """
  @callback sense(
              robot :: %Robot{},
              sensor :: %__MODULE__{},
              sense :: atom | {atom, any},
              tile :: %Tile{},
              tiles :: [%Tile{}],
              robots :: [Robot.t()]
            ) :: any

  @doc """
  Get the module for a type of sensor
  """
  @spec module_for(sensor_type()) :: module()
  def module_for(sensor_type) do
    case sensor_type do
      :light -> Light
      :infrared -> Infrared
      :touch -> Touch
      :ultrasonic -> Ultrasonic
      :tacho_motor -> Motor
    end
  end

  @doc """
  Make a sensor from data
  """
  @spec from(map()) :: t()
  def from(%{
        device_id: device_id,
        device_class: :sensor,
        device_type: device_type,
        properties: properties
      }) do
    position = Map.get(properties, :position, @default_position)
    height_cm = Map.get(properties, :height_cm, @default_height_cm)
    aim = Map.get(properties, :aim, @default_aim)

    %__MODULE__{
      id: device_id,
      type: device_type,
      position: position,
      height_cm: height_cm,
      aim: aim_to_integer(aim)
    }
  end

  # For testing
  def from(%{
        device_id: device_id,
        device_class: :sensor,
        device_type: device_type,
        position: position,
        aim: aim,
        height_cm: height_cm
      }) do
    %__MODULE__{
      id: device_id,
      type: device_type,
      position: position,
      height_cm: height_cm,
      aim: aim_to_integer(aim)
    }
  end

  @doc """
  Whether a sensor is of a given type
  """
  @spec has_type?(t(), sensor_type()) :: boolean()
  def has_type?(%{type: type}, sensor_type), do: type == sensor_type

  @doc """
  Get the absolute orientation of a sensor
  """
  @spec absolute_orientation(integer(), integer()) :: integer()
  def absolute_orientation(sensor_aim, robot_orientation) do
    (robot_orientation + sensor_aim)
    |> Space.normalize_orientation()
  end

  defp aim_to_integer(aim) when is_atom(aim) do
    case aim do
      :forward -> 0
      :right -> 90
      :backward -> 180
      :left -> -90
      :downward -> 0
    end
  end

  defp aim_to_integer(aim) when is_integer(aim), do: aim
end
