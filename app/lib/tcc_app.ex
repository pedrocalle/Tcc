defmodule TccApp do
  use Application

  def start(_type, _args) do
    children = [
      MqttClient
    ]

    opts = [strategy: :one_for_one, name: TccApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
