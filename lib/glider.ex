defmodule Glider do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  @pause_between_sensors_reads 5

  def init(opts) do
    bno055 = BNO055.setup(:NDOF)
    pitch = %Glider.PitchFeedback{
      offset: -3.0,
      reversed: false,
      sensor_ceiling: 20.0,
      sensor_floor: -20.0,
      servo_max: 2000,
      servo_min: 1500
    }
    opts = Keyword.put(opts, :bno055, bno055) |> Keyword.put(:pitch, pitch)
    send self(), :refresh
    {:ok, opts}
  end

  def handle_info(:refresh, state) do
    {:ok, %{pitch: pitch}} = Keyword.get(state, :bno055) |> BNO055.orientation()
    elevator_pin = Keyword.get(state, :elevator_pin)
    pitch_feedback = Keyword.get(state, :pitch)
    pulsewidth = Glider.PitchFeedback.servo_pulsewidth(pitch, pitch_feedback)
    Pigpiox.GPIO.set_servo_pulsewidth(elevator_pin, pulsewidth)
    Process.send_after(self(), :refresh, @pause_between_sensors_reads)
    {:noreply, state}
  end
end
