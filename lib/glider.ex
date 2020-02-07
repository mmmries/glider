defmodule Glider do
  use GenServer
  require Logger
  alias Glider.Elevon
  alias BNO055.Smoothing

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    bno055 = BNO055.setup(:NDOF)
    elevon = %Elevon{
      desired_heading: 0.0,
      desired_pitch: -4.0,
      left_center: 1430,
      left_direction: -1,
      right_center: 1470,
      right_direction: 1,
    }
    opts = opts
      |> Keyword.put(:bno055, bno055)
      |> Keyword.put(:elevon, elevon)
      |> Keyword.put(:smoothing, Smoothing.init())
    send self(), :refresh
    {:ok, opts}
  end

  @pause_between_sensors_reads 33
  @left_pin 13
  @right_pin 18
  def handle_info(:refresh, state) do
    {:ok, orientation} = Keyword.get(state, :bno055) |> BNO055.orientation()
    state = if orientation_reasonable?(orientation) do

      {smoothing, orientation} = Keyword.get(state, :smoothing) |> Smoothing.reading(orientation)
      {left, right} = state |> Keyword.get(:elevon) |> Elevon.feedback(orientation)

      Pigpiox.GPIO.set_servo_pulsewidth(@left_pin, left)
      Pigpiox.GPIO.set_servo_pulsewidth(@right_pin, right)
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
