defmodule Glider.HeadingFeedback do
  @moduledoc """
  A module to calculate a desired servo position given the current heading angle (0° to +360°)
  and current roll angle (-180° to +180°)

  This module represents a direct feedback loop where we derive a desired servo position from the current sensor data.
  No smoothing function, rate of change or delay is taken into account.
  The BNO055 sensor I'm using sometimes produces angles slightly higher than 360 (ie 366.5 degrees).
  """

  defstruct desired: 0.0,
            reversed: false,
            max_roll: 10.0,
            servo_center: 1500,
            servo_range: 300

  alias Glider.Circle

  def servo_pulsewidth(heading, roll, %__MODULE__{}=feedback) do
    heading
    |> Circle.wrap()
    |> heading_difference_from(feedback)
    |> desired_roll(feedback)
    |> roll_diff_ratio(roll, feedback.max_roll)
    |> diff_to_pulsewidth(feedback)
  end

  defp desired_roll(heading_diff, %__MODULE__{max_roll: max}) do
    (heading_diff * 0.15) |> clamp(max)
  end

  defp diff_to_pulsewidth(roll_diff_ratio, %__MODULE__{}=feedback) do
    servo_offset = :erlang.round(roll_diff_ratio * feedback.servo_range)
    case feedback.reversed do
      false -> feedback.servo_center - servo_offset
      true -> feedback.servo_center + servo_offset
    end
  end

  defp heading_difference_from(current, %__MODULE__{desired: desired}) do
    Circle.difference(desired, current)
  end

  defp clamp(roll, max) when roll > max, do: max
  defp clamp(roll, max) when roll < (-1 * max), do: -1 * max
  defp clamp(roll, _max), do: roll

  defp roll_diff_ratio(desired_roll, current_roll, max) do
    ((desired_roll - current_roll) / max) |> clamp(1.0)
  end
end
