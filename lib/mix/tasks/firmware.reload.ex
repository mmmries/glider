defmodule Mix.Tasks.Firmware.Reload do
  use Mix.Task

  def run(_) do
    node_name = :"glider@glider.local"
    {:ok, _} = Node.start(:host_machine)
    Node.set_cookie(:glider_cookie)
    true = Node.connect(node_name)
    applications = [:bno055, :glider]
    for app <- applications do
      Application.load(app)
      {:ok, my_app_mods} = :application.get_key(app, :modules)
      for module <- my_app_mods do
        {:ok, [{^node_name, :loaded, ^module}]} = IEx.Helpers.nl([node_name], module)
      end
    end
  end
end
