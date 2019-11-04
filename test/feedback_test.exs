defmodule Glider.FeedbackTest do
  use ExUnit.Case
  alias Glider.Feedback

  setup do
    feedback = %Feedback{
      sensor_ceiling: 45.0,
      sensor_floor: -45.0,
      servo_max: 1800,
      servo_min: 1200
    }
    {:ok, %{feedback: feedback}}
  end

  test "centering the servo when we are on course", %{feedback: feedback} do
    assert Feedback.servo_pulsewidth(0.0, feedback) == 1500
  end

  test "pulling up when the nose dips", %{feedback: feedback} do
    assert Feedback.servo_pulsewidth(-4.5, feedback) >= 1500
    assert Feedback.servo_pulsewidth(-4.5, feedback) <= 1550
  end

  test "pulling up hard if the nose is way down", %{feedback: feedback} do
    assert Feedback.servo_pulsewidth(-45.0, feedback) == 1800
    assert Feedback.servo_pulsewidth(-90.0, feedback) == 1800
  end
end
