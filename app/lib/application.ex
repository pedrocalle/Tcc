defmodule EstufaApp.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # inicia o GenServer MQTT automaticamente
      {MqttClient, []}
    ]

    opts = [strategy: :one_for_one, name: EstufaApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
