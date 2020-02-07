defmodule Glider do
  use GenServer
  require Logger
  alias Glider.{PitchFeedback, HeadingFeedback}
  alias BNO055.Smoothing

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    bno055 = BNO055.setup(:NDOF)
    pitch = %PitchFeedback{
      offset: 8.0,
      reversed: false,
      sensor_ceiling: 20.0,
      sensor_floor: -20.0,
      servo_max: 1750,
      servo_min: 1250
    }
    heading = %HeadingFeedback{
      desired: 0.0,
      reversed: true,
      max_roll: 15.0,
      roll_offset: 5.0,
      servo_center: 1450,
      servo_range: 300
    }
    opts = opts
      |> Keyword.put(:bno055, bno055)
      |> Keyword.put(:pitch, pitch)
      |> Keyword.put(:heading, heading)
      |> Keyword.put(:smoothing, Smoothing.init())
    send self(), :refresh
    {:ok, opts}
  end

  @pause_between_sensors_reads 33
  @elevator_pin 13
  @rudder_pin 12
  def handle_info(:refresh, state) do
    {:ok, orientation} = Keyword.get(state, :bno055) |> BNO055.orientation()
    state = if orientation_reasonable?(orientation) do
      {smoothing, orientation} = Keyword.get(state, :smoothing) |> Smoothing.reading(orientation)
      #Logger.info("orientation: #{inspect(orientation)}")

      pitch_feedback = Keyword.get(state, :pitch)
      pulsewidth = PitchFeedback.servo_pulsewidth(orientation.pitch, pitch_feedback)
      Pigpiox.GPIO.set_servo_pulsewidth(@elevator_pin, pulsewidth)

      heading_feedback = Keyword.get(state, :heading)
      pulsewidth = HeadingFeedback.servo_pulsewidth(orientation.heading, orientation.roll, heading_feedback)
      Pigpiox.GPIO.set_servo_pulsewidth(@rudder_pin, pulsewidth)

      Keyword.put(state, :smoothing, smoothing)
    else
      Logger.error("Invalid Orientation Data")
      state
    end

    Process.send_after(self(), :refresh, @pause_between_sensors_reads)

    {:noreply, state}
  end

  def orientation_reasonable?(%{heading: heading, pitch: pitch, roll: roll}) do
    heading > -20.0 and heading <= 380.0 and pitch >= -200.0 and pitch <= 200.0 and roll >= -200.0 and roll <= 200.0
  end
end
