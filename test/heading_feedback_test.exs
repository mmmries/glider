defmodule Glider.HeadingFeedbackTest do
  use ExUnit.Case
  alias Glider.HeadingFeedback

  describe "wrap around and overflow" do
    setup do
      feedback = %HeadingFeedback{
        sensor_ceiling: 11.0,
        sensor_floor: 351.0,
        servo_max: 1800,
        servo_min: 1200
      }
      {:ok, %{feedback: feedback}}
    end

    test "centering the servo when we are on course", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(1.0, feedback) == 1500
    end

    test "handling wrap around scenarios", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(11.0, feedback) == 1800
      assert HeadingFeedback.servo_pulsewidth(351.0, feedback) == 1200
    end

    test "handling sensor readings > 360.0", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(361.0, feedback) == 1500
      assert HeadingFeedback.servo_pulsewidth(371.0, feedback) == 1800
    end

    test "handling sensor readings < 0.0", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(-9.0, feedback) == 1200
      assert HeadingFeedback.servo_pulsewidth(-1.0, feedback) == 1440
    end
  end

  describe "reversing" do
    setup do
      feedback = %HeadingFeedback{
        reversed: true,
        sensor_ceiling: 11.0,
        sensor_floor: 351.0,
        servo_max: 1800,
        servo_min: 1200
      }
      {:ok, %{feedback: feedback}}
    end

    test "centering the servo when we are on course", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(1.0, feedback) == 1500
    end

    test "handling wrap around scenarios", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(11.0, feedback) == 1200
      assert HeadingFeedback.servo_pulsewidth(351.0, feedback) == 1800
    end

    test "handling sensor readings > 360.0", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(361.0, feedback) == 1500
      assert HeadingFeedback.servo_pulsewidth(371.0, feedback) == 1200
    end

    test "handling sensor readings < 0.0", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(-9.0, feedback) == 1800
      assert HeadingFeedback.servo_pulsewidth(-1.0, feedback) == 1560
    end
  end
end
