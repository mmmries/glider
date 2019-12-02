defmodule Glider.HeadingFeedback do
  @moduledoc """
  A module to calculate a desired servo position given the current heading angle (0° to +360°)

  This module represents a direct feedback loop where we derive a desired servo position from the current sensor data.
  No smoothing function, rate of change or delay is taken into account.
  The BNO055 sensor I'm using sometimes produces angles slightly higher than 360 (ie 366.5 degrees).
  """

  defstruct desired: 0.0,
            reversed: false,
            sensor_range: 20.0,
            servo_center: 1500,
            servo_range: 300

  alias Glider.Circle

  def servo_pulsewidth(heading, feedback) do
    heading = Circle.wrap(heading)
    diff =  Circle.difference(feedback.desired, heading) |> clamp(feedback)
    servo_offset = :erlang.round((diff / feedback.sensor_range) * feedback.servo_range)
    case feedback.reversed do
      false -> feedback.servo_center - servo_offset
      true -> feedback.servo_center + servo_offset
    end
  end

  defp clamp(diff, %{sensor_range: range}) when diff > range, do: range
  defp clamp(diff, %{sensor_range: range}) when diff < (-1 * range), do: -1 * range
  defp clamp(diff, _feedback), do: diff
end
