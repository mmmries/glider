defmodule Glider do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  @pause_between_sensors_reads 1000

  def init(opts) do
    bno055 = BNO055.setup(:NDOF)
    pitch = %Glider.PitchFeedback{
      offset: -2.0,
      reversed: false,
      sensor_ceiling: 20.0,
      sensor_floor: -20.0,
      servo_max: 2000,
      servo_min: 1500
    }
    heading = %Glider.HeadingFeedback{
      desired: 0.0,
      reversed: true,
      max_roll: 10.0,
      servo_center: 1500,
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
      pulsewidth = Glider.PitchFeedback.servo_pulsewidth(pitch, pitch_feedback)
      Pigpiox.GPIO.set_servo_pulsewidth(@elevator_pin, pulsewidth)
    end

    if reading_reasonable?(heading) and reading_reasonable?(roll) do
      heading_feedback = Keyword.get(state, :heading)
      pulsewidth = Glider.HeadingFeedback.servo_pulsewidth(heading, roll, heading_feedback)
      Pigpiox.GPIO.set_servo_pulsewidth(@heading_pin, pulsewidth)
    end

    Process.send_after(self(), :refresh, @pause_between_sensors_reads)
    {:noreply, state}
  end

  defp reading_reasonable?(reading) when reading < -180.0, do: false
  defp reading_reasonable?(reading) when reading > 390.0, do: false
  defp reading_reasonable?(_reading), do: true
end
