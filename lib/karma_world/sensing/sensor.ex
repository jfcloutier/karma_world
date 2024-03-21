defmodule KarmaWorld.Sensing.Sensor do
  @moduledoc """
  Data about a sensor
  """

  alias __MODULE__
  alias KarmaWorld.Sensing.{Light, Infrared, Touch, Ultrasonic}
  alias KarmaWorld.{Robot, Space, Tile}

  @type position :: :left | :right | :top | :front | :back
  @type sensor_type :: :infrared | :light | :touch | :ultrasonic
  @type t :: %__MODULE__{
          connection: String.t(),
          type: atom(),
          # where the sensor is positioned on the robot, one of :left, :right, :top, :front, :back
          position: position(),
          # how high is the sensor riding on the robot
          height_cm: integer(),
          # which way is the sensor pointing, # an angle between -180 and 180
          aim: integer()
        }

  defstruct connection: nil,
            type: nil,
            position: nil,
            height_cm: nil,
            aim: nil

  @doc """
  Read a robot's sensor
  """
  @callback sense(
              robot :: %Robot{},
              sensor :: %Sensor{},
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
    end
  end

  @doc """
  Make a sensor from data
  """
  @spec from(%{
          :aim => integer(),
          :connection => String.t(),
          :height_cm => non_neg_integer(),
          :position => position(),
          :type => sensor_type()
        }) :: t()
  def from(%{
        connection: connection,
        type: type,
        position: position,
        height_cm: height_cm,
        aim: aim
      }) do
    %Sensor{
      connection: connection,
      type: type,
      position: position,
      height_cm: height_cm,
      aim: aim
    }
  end

  @doc """
  Whether a sensor is of a given type
  """
  @spec has_type?(t(), sensor_type()) :: boolean()
  def has_type?(%Sensor{type: type}, sensor_type), do: type == sensor_type

  @doc """
  Get the absolute orientation of a sensor
  """
  @spec absolute_orientation(integer(), integer()) :: integer()
  def absolute_orientation(sensor_aim, robot_orientation) do
    (robot_orientation + sensor_aim)
    |> Space.normalize_orientation()
  end
end
