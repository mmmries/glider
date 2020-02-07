defmodule Glider.Elevon do
  alias Glider.Circle
  defstruct [:desired_heading, :desired_pitch, :left_center, :left_direction, :right_center, :right_direction]

  def feedback(%__MODULE__{}=config, orientation) do
    center = {config.left_center, config.right_center}
    directions = {config.left_direction, config.right_direction}
    vertical = vertical_bias(config, orientation)
    roll = roll_bias(config, orientation)
    combine(center, directions, vertical, roll)
  end

  @doc "represent how far the nose is up-or-down in terms of a servo pulsewidth offset"
  def vertical_bias(%__MODULE__{desired_pitch: desired}, %{pitch: actual}) do
    diff = clamp(actual - desired, 30.0)
    {diff * 15, diff * 15}
  end

  @roll_ratio 1.0 # a ratio of how much roll we should have for a given heading difference
  @max_roll 20.0 # the maximum roll angle we'll sustain
  def roll_bias(%__MODULE__{desired_heading: desired}, %{roll: roll, heading: heading}) do
    heading = Circle.wrap(heading)
    heading_diff = Circle.difference(desired, heading)
    desired_roll = (heading_diff * @roll_ratio) |> clamp(@max_roll)
    roll_diff = clamp(roll - desired_roll, 30.0)
    {roll_diff * -15, roll_diff * 15}
  end

  defp clamp(number, max), do: clamp(number, -1 * max, max)

  defp clamp(number, min, _max) when number < min, do: min
  defp clamp(number, _min, max) when number > max, do: max
  defp clamp(number, _min, _max), do: number

  defp combine({cl, cr}, {dl, dr}, {vl, vr}, {rl, rr}) do
    {
      (cl + dl * (vl + rl)) |> trunc() |> clamp(1000, 2000),
      (cr + dr * (vr + rr)) |> trunc() |> clamp(1000, 2000),
    }
  end
end
