defmodule Glider.HeadingFeedback do
  @moduledoc """
  A module to calculate a desired servo position given the current heading angle (0° to +360°)

  This module represents a direct feedback loop where we derive a desired servo position from the current sensor data.
  No smoothing function, rate of change or delay is taken into account.
  The BNO055 sensor I'm using sometimes produces angles slightly higher than 360 (ie 366.5 degrees).
  """

  defstruct reversed: false,
            sensor_ceiling: 45.0,
            sensor_floor: -45.0,
            servo_max: 1800,
            servo_min: 1200
end
