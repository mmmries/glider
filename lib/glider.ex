defmodule Glider do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    bno055 = BNO055.setup(:NDOF)
    opts = Keyword.put(opts, :bno055, bno055)
    send self(), :refresh
    {:ok, opts}
  end

  @max_up_servo 2000
  @max_down_servo 1500
  @max_up_angle 20.0
  @max_down_angle -20.0
  @pause_between_sensors_reads 10

  def handle_info(:refresh, state) do
    {:ok, %{pitch: pitch}} = Keyword.get(state, :bno055) |> BNO055.orientation()
    pitch = clamp_pitch(pitch)
    sensor_ratio = (@max_up_angle - pitch) / (@max_up_angle - @max_down_angle)
    servo_position = ceil((sensor_ratio * (@max_up_servo - @max_down_servo)) + @max_down_servo)
    elevator_pin = Keyword.get(state, :elevator_pin)
    Pigpiox.GPIO.set_servo_pulsewidth(elevator_pin, servo_position)
    Process.send_after(self(), :refresh, @pause_between_sensors_reads)
    {:noreply, state}
  end

  defp clamp_pitch(pitch) when pitch < @max_down_angle, do: @max_down_angle
  defp clamp_pitch(pitch) when pitch > @max_up_angle, do: @max_up_angle
  defp clamp_pitch(pitch), do: pitch

end
