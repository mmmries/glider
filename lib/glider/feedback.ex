defmodule Glider.Feedback do
  @moduledoc """
  A module to calculate a desired servo position given new sensor data

  This module represents a direct feedback loop where we derive a desired servo position from the current sensor data.
  No smoothing function, rate of change or delay is taken into account.
  """

  defstruct sensor_ceiling: 45.0,
            sensor_floor: -45.0,
            servo_max: 1800,
            servo_min: 1200

  def servo_pulsewidth(sensor, feedback) do
    sensor = clamp_sensor(sensor, feedback)
    sensor_ratio = (feedback.sensor_ceiling - sensor) / (feedback.sensor_ceiling - feedback.sensor_floor)
    ceil((sensor_ratio * (feedback.servo_max - feedback.servo_min)) + feedback.servo_min)
  end

  defp clamp_sensor(sensor, %__MODULE__{sensor_floor: floor}) when sensor < floor, do: floor
  defp clamp_sensor(sensor, %__MODULE__{sensor_ceiling: ceiling}) when sensor > ceiling, do: ceiling
  defp clamp_sensor(sensor, _feedback), do: sensor
end
