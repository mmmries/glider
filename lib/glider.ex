defmodule Glider do
  use GenServer
  require Logger
  alias Glider.Elevon

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    bno055 = BNO055.setup(:NDOF)
    elevon = %Elevon{
      desired_heading: 0.0,
      desired_pitch: 0.0,
      left_center: 1500,
      left_direction: -1,
      right_center: 1500,
      right_direction: 1,
    }
    opts = opts
      |> Keyword.put(:bno055, bno055)
      |> Keyword.put(:elevon, elevon)
    send self(), :refresh
    {:ok, opts}
  end

  @pause_between_sensors_reads 50
  @left_pin 18
  @right_pin 13
  def handle_info(:refresh, state) do
    {:ok, orientation} = Keyword.get(state, :bno055) |> BNO055.orientation()
    {left, right} = state |> Keyword.get(:elevon) |> Elevon.feedback(orientation)

    Pigpiox.GPIO.set_servo_pulsewidth(@left_pin, left)
    Pigpiox.GPIO.set_servo_pulsewidth(@right_pin, right)

    Process.send_after(self(), :refresh, @pause_between_sensors_reads)
    {:noreply, state}
  end
end
