defmodule Glider.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Glider.Supervisor]

    Supervisor.start_link(children(target()), opts)
  end

  def children(:host), do: []

  def children(_target) do
    [
      {Glider, []}
    ]
  end

  def target() do
    Application.get_env(:glider, :target)
  end
end
