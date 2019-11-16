defmodule Glider.PitchFeedbackTest do
  use ExUnit.Case
  alias Glider.PitchFeedback

  setup do
    feedback = %PitchFeedback{
      offset: 0,
      reversed: false,
      sensor_ceiling: 45.0,
      sensor_floor: -45.0,
      servo_max: 1800,
      servo_min: 1200
    }
    {:ok, %{feedback: feedback}}
  end

  test "centering the servo when we are on course", %{feedback: feedback} do
    assert PitchFeedback.servo_pulsewidth(0.0, feedback) == 1500
  end

  test "pulling up when the nose dips", %{feedback: feedback} do
    assert PitchFeedback.servo_pulsewidth(-4.5, feedback) >= 1500
    assert PitchFeedback.servo_pulsewidth(-4.5, feedback) <= 1550
  end

  test "pulling up hard if the nose is way down", %{feedback: feedback} do
    assert PitchFeedback.servo_pulsewidth(-45.0, feedback) == 1800
    assert PitchFeedback.servo_pulsewidth(-90.0, feedback) == 1800
  end

  describe "reversing" do
    setup do
      feedback = %PitchFeedback{
        offset: 0,
        reversed: true,
        sensor_ceiling: 45.0,
        sensor_floor: -45.0,
        servo_max: 1800,
        servo_min: 1200
      }
      {:ok, %{feedback: feedback}}
    end

    test "centering the servo when we are on course", %{feedback: feedback} do
      assert PitchFeedback.servo_pulsewidth(0.0, feedback) == 1500
    end

    test "pulling up when the nose dips", %{feedback: feedback} do
      assert PitchFeedback.servo_pulsewidth(-4.5, feedback) <= 1500
      assert PitchFeedback.servo_pulsewidth(-4.5, feedback) >= 1450
    end

    test "pulling up hard if the nose is way down", %{feedback: feedback} do
      assert PitchFeedback.servo_pulsewidth(-45.0, feedback) == 1200
      assert PitchFeedback.servo_pulsewidth(-90.0, feedback) == 1200
    end
  end

  describe "offset" do
    setup do
      feedback = %PitchFeedback{
        offset: -4.5,
        reversed: false,
        sensor_ceiling: 45.0,
        sensor_floor: -45.0,
        servo_max: 1800,
        servo_min: 1200
      }
      {:ok, %{feedback: feedback}}
    end

    test "center reading actually means an up-pitch", %{feedback: feedback} do
      assert PitchFeedback.servo_pulsewidth(0.0, feedback) > 1500
      assert PitchFeedback.servo_pulsewidth(0.0, feedback) <= 1550
    end

    test "slight up-pitch actually means center", %{feedback: feedback} do
      assert PitchFeedback.servo_pulsewidth(4.5, feedback) == 1500
    end
  end
end
