defmodule Glider do
  use GenServer
  require Logger
  alias Glider.{Circle,HeadingFeedback,PitchFeedback}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  @pause_between_sensors_reads 5
  @desired_heading 135.0

  def init(opts) do
    bno055 = BNO055.setup(:NDOF)
    pitch = %PitchFeedback{
      offset: -1.0,
      reversed: false,
      sensor_ceiling: 20.0,
      sensor_floor: -20.0,
      servo_max: 2000,
      servo_min: 1500
    }
    heading = %HeadingFeedback{
      desired: 0.0,
      reversed: true,
      max_roll: 15.0,
      servo_center: 1575,
      servo_range: 300
    }
    opts = opts
      |> Keyword.put(:bno055, bno055)
      |> Keyword.put(:heading, heading)
      |> Keyword.put(:pitch, pitch)
    send self(), :refresh
    {:ok, opts}
  end

  @elevator_pin 18
  @heading_pin 13
  def handle_info(:refresh, state) do
    {:ok, orientation} = Keyword.get(state, :bno055) |> BNO055.orientation()
    %{heading: heading, pitch: pitch, roll: roll} = orientation

    if reading_reasonable?(pitch) do
      pitch_feedback = Keyword.get(state, :pitch)
      pulsewidth = PitchFeedback.servo_pulsewidth(pitch, pitch_feedback)
      Pigpiox.GPIO.set_servo_pulsewidth(@elevator_pin, pulsewidth)
    end

    if reading_reasonable?(heading) and reading_reasonable?(roll) do
      heading_feedback = Keyword.get(state, :heading) |> update_desired_heading(heading)
      Logger.info("Current Heading #{heading}, Desired: #{heading_feedback.desired}")
      pulsewidth = HeadingFeedback.servo_pulsewidth(heading, roll, heading_feedback)
      Pigpiox.GPIO.set_servo_pulsewidth(@heading_pin, pulsewidth)
    end

    Process.send_after(self(), :refresh, @pause_between_sensors_reads)
    {:noreply, state}
  end

  defp reading_reasonable?(reading) when reading < -180.0, do: false
  defp reading_reasonable?(reading) when reading > 390.0, do: false
  defp reading_reasonable?(_reading), do: true

  defp update_desired_heading(feedback, heading) do
    diff = Circle.difference(@desired_heading, heading)
    if abs(diff) < 90.0 do
      %{feedback | desired: @desired_heading}
    else
      %{feedback | desired: Circle.wrap(@desired_heading + 180.0)}
    end
  end
end
