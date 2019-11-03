defmodule Glider do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    :timer.send_interval(50, :refresh)
    bno055 = BNO055.setup(:NDOF)
    opts = Keyword.put(opts, :bno055, bno055)
    {:ok, opts}
  end

  @max_up_servo 1800
  @max_down_servo 1200
  @max_up_angle 45.0
  @max_down_angle -45.0

  def handle_info(:refresh, state) do
    {:ok, %{pitch: pitch}} = Keyword.get(state, :bno055) |> BNO055.orientation()
    pitch = clamp_pitch(pitch)
    sensor_ratio = (@max_up_angle - pitch) / (@max_up_angle - @max_down_angle)
    servo_position = ceil((sensor_ratio * (@max_up_servo - @max_down_servo)) + @max_down_servo)
    elevator_pin = Keyword.get(state, :elevator_pin)
    Pigpiox.GPIO.set_servo_pulsewidth(elevator_pin, servo_position)
    {:noreply, state}
  end

  defp clamp_pitch(pitch) when pitch < @max_down_angle, do: @max_down_angle
  defp clamp_pitch(pitch) when pitch > @max_up_angle, do: @max_up_angle
  defp clamp_pitch(pitch), do: pitch

end
