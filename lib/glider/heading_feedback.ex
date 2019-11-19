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

  def servo_pulsewidth(heading, feedback) do
    heading = wrap(heading)
    diff = difference_from_desired(heading, feedback) |> clamp(feedback)
    servo_offset = :erlang.round((diff / feedback.sensor_range) * feedback.servo_range)
    case feedback.reversed do
      false -> feedback.servo_center - servo_offset
      true -> feedback.servo_center + servo_offset
    end
  end

  defp clamp(diff, %{sensor_range: range}) when diff > range, do: range
  defp clamp(diff, %{sensor_range: range}) when diff < (-1 * range), do: -1 * range
  defp clamp(diff, _feedback), do: diff

  @max_angle 360.0
  defp wrap(heading) when heading > @max_angle do
    heading - @max_angle
  end
  defp wrap(heading) when heading < 0.0 do
    @max_angle + heading
  end
  defp wrap(heading), do: heading

  defp difference_from_desired(heading, %__MODULE__{desired: desired}) do
    case desired - heading do
      diff when diff < -180.0 -> diff + 360.0
      diff when diff > 180.0 -> diff - 360.0
      diff -> diff
    end
  end
end
