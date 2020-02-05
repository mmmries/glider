defmodule Glider.ElevonTest do
  use ExUnit.Case
  alias Glider.Elevon

  test "on-course, keep it straight and level" do
    config = create_config()
    assert {1500, 1500} = Elevon.feedback(config, %{heading: 0.0, pitch: 0.0, roll: 0.0})
    config = create_config(%{left_center: 1425})
    assert {1425, 1500} = Elevon.feedback(config, %{heading: 360.0, pitch: 0.0, roll: 0.0})
  end

  test "on-course, nose down => pull up" do
    config = create_config()
    orientation = %{heading: 0.0, pitch: -5.0, roll: 0.0}
    assert {left, right} = Elevon.feedback(config, orientation)
    assert_in_delta left, 1550, 10
    assert_in_delta right, 1450, 10

    config = create_config(%{desired_pitch: 5.0})
    orientation = %{heading: 0.0, pitch: 0.0, roll: 0.0}
    assert {left, right} = Elevon.feedback(config, orientation)
    assert_in_delta left, 1550, 10
    assert_in_delta right, 1450, 10
  end

  test "on-course, nose up => push down" do
    config = create_config()
    orientation = %{heading: 0.0, pitch: 5.0, roll: 0.0}
    assert {left, right} = Elevon.feedback(config, orientation)
    assert_in_delta left, 1450, 10
    assert_in_delta right, 1550, 10

    config = create_config(%{desired_pitch: -5.0})
    orientation = %{heading: 0.0, pitch: 0.0, roll: 0.0}
    assert {left, right} = Elevon.feedback(config, orientation)
    assert_in_delta left, 1450, 10
    assert_in_delta right, 1550, 10
  end

  test "on-course, leaning right => roll left" do
    config = create_config()
    orientation = %{heading: 0.0, pitch: 0.0, roll: 5.0}
    assert {left, right} = Elevon.feedback(config, orientation)
    assert_in_delta left, 1550, 10
    assert_in_delta right, 1550, 10
  end

  test "on-course, leaning left => roll right" do
    config = create_config()
    orientation = %{heading: 0.0, pitch: 0.0, roll: -5.0}
    assert {left, right} = Elevon.feedback(config, orientation)
    assert_in_delta left, 1450, 10
    assert_in_delta right, 1450, 10
  end

  test "on-course, nose-down, leaning right => roll left, pull up" do
    config = create_config()
    orientation = %{heading: 0.0, pitch: -5.0, roll: 5.0}
    assert {left, right} = Elevon.feedback(config, orientation)
    assert_in_delta left, 1600, 10
    assert_in_delta right, 1500, 10
  end

  defp create_config(settings \\ %{}) do
    %Elevon{
      desired_heading: 0.0,
      desired_pitch: 0.0,
      left_center: 1500,
      left_direction: 1,
      right_center: 1500,
      right_direction: -1,
    } |> Map.merge(settings)
  end
end
