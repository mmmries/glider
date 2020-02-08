defmodule Glider do
  use GenServer
  require Logger
  alias Glider.{PitchFeedback, HeadingFeedback}
  alias BNO055.{Circle, Smoothing}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    bno055 = BNO055.setup(:NDOF)
    pitch = %PitchFeedback{
      offset: 6.0,
      reversed: false,
      sensor_ceiling: 30.0,
      sensor_floor: -30.0,
      servo_max: 1620 + 250,
      servo_min: 1620 - 250
    }
    heading = %HeadingFeedback{
      desired: 0.0,
      reversed: true,
      max_roll: 15.0,
      roll_offset: 3.0,
      servo_center: 1360,
      servo_range: 300
    }
    opts = opts
      |> Keyword.put(:bno055, bno055)
      |> Keyword.put(:pitch, pitch)
      |> Keyword.put(:heading, heading)
      |> Keyword.put(:smoothing, Smoothing.init())
      |> Keyword.put(:candidate_heading, 0.0)
      |> Keyword.put(:candidate_observations, 0)
    send self(), :refresh
    {:ok, opts}
  end

  @pause_between_sensors_reads 16
  @elevator_pin 13
  @rudder_pin 12
  def handle_info(:refresh, state) do
    {:ok, orientation} = Keyword.get(state, :bno055) |> BNO055.orientation()
    state = if orientation_reasonable?(orientation, state) do
      {orientation, state} = smooth(orientation, state)
      state = lock_in_new_heading(orientation, state)
      update_servos(orientation, state)
      state
    else
      Logger.error("Invalid Orientation Data")
      state
    end

    Process.send_after(self(), :refresh, @pause_between_sensors_reads)

    {:noreply, state}
  end

  defp smooth(orientation, state) do
    {smoothing, orientation} = Keyword.get(state, :smoothing) |> Smoothing.reading(orientation)
    state = Keyword.put(state, :smoothing, smoothing)
    #Logger.info("orientation: #{inspect(orientation)}")
    #Logger.info("heading: #{orientation.heading}")
    {orientation, state}
  end

  @observations_before_adoption 200
  @observations_tolerance 2.0
  defp lock_in_new_heading(%{heading: h}, state) do
    candidate = Keyword.get(state, :candidate_heading)
    if abs(Circle.difference(h, candidate)) < @observations_tolerance do
      observations = Keyword.get(state, :candidate_observations) + 1
      if observations >= @observations_before_adoption do
        heading = state |> Keyword.get(:heading) |> Map.put(:desired, candidate)
        Logger.info("Locked in new heading: #{candidate}")
        state |> Keyword.put(:candidate_heading, h) |> Keyword.put(:candidate_observations, 0) |> Keyword.put(:heading, heading)
      else
        state |> Keyword.put(:candidate_observations, observations)
      end
    else
      state |> Keyword.put(:candidate_heading, h) |> Keyword.put(:candidate_observations, 0)
    end
  end

  defp update_servos(orientation, state) do
    pitch_feedback = Keyword.get(state, :pitch)
    pulsewidth = PitchFeedback.servo_pulsewidth(orientation.pitch, pitch_feedback)
    Pigpiox.GPIO.set_servo_pulsewidth(@elevator_pin, pulsewidth)

    heading_feedback = Keyword.get(state, :heading)
    pulsewidth = HeadingFeedback.servo_pulsewidth(orientation.heading, orientation.roll, heading_feedback)
    Pigpiox.GPIO.set_servo_pulsewidth(@rudder_pin, pulsewidth)
  end

  def orientation_reasonable?(%{heading: heading, pitch: pitch, roll: roll}, _state) do
    heading > -20.0 and heading <= 380.0 and pitch >= -200.0 and pitch <= 200.0 and roll >= -200.0 and roll <= 200.0
  end
end
