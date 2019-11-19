defmodule Glider.HeadingFeedbackTest do
  use ExUnit.Case
  alias Glider.HeadingFeedback

  describe "wrap around and overflow" do
    setup do
      feedback = %HeadingFeedback{
        desired: 0.0,
        reversed: false,
        sensor_range: 20.0,
        servo_center: 1500,
        servo_range: 300,
      }
      {:ok, %{feedback: feedback}}
    end

    test "centering the servo when we are on course", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(0.0, feedback) == 1500
    end

    test "handling wrap around scenarios", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(10.0, feedback) == 1650
      assert HeadingFeedback.servo_pulsewidth(20.0, feedback) == 1800
      assert HeadingFeedback.servo_pulsewidth(350.0, feedback) == 1350
      assert HeadingFeedback.servo_pulsewidth(340.0, feedback) == 1200
    end

    test "handling sensor readings > 360.0", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(360.0, feedback) == 1500
      assert HeadingFeedback.servo_pulsewidth(370.0, feedback) == 1650
      assert HeadingFeedback.servo_pulsewidth(380.0, feedback) == 1800
    end

    test "handling sensor readings < 0.0", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(0.0, feedback) == 1500
      assert HeadingFeedback.servo_pulsewidth(-10.0, feedback) == 1350
      assert HeadingFeedback.servo_pulsewidth(-20.0, feedback) == 1200
    end
  end

  describe "reversing" do
    setup do
      feedback = %HeadingFeedback{
        desired: 0.0,
        reversed: true,
        sensor_range: 20.0,
        servo_center: 1500,
        servo_range: 300,
      }
      {:ok, %{feedback: feedback}}
    end

    test "centering the servo when we are on course", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(0.0, feedback) == 1500
    end

    test "handling wrap around scenarios", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(10.0, feedback) == 1350
      assert HeadingFeedback.servo_pulsewidth(20.0, feedback) == 1200
      assert HeadingFeedback.servo_pulsewidth(350.0, feedback) == 1650
      assert HeadingFeedback.servo_pulsewidth(340.0, feedback) == 1800
    end

    test "handling sensor readings > 360.0", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(360.0, feedback) == 1500
      assert HeadingFeedback.servo_pulsewidth(370.0, feedback) == 1350
      assert HeadingFeedback.servo_pulsewidth(380.0, feedback) == 1200
    end

    test "handling sensor readings < 0.0", %{feedback: feedback} do
      assert HeadingFeedback.servo_pulsewidth(0.0, feedback) == 1500
      assert HeadingFeedback.servo_pulsewidth(-10.0, feedback) == 1650
      assert HeadingFeedback.servo_pulsewidth(-20.0, feedback) == 1800
    end
  end
end
