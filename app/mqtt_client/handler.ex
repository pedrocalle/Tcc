defmodule MqttClient.Handler do
  @behaviour Tortoise311.Handler
  require Logger

  def init(args), do: {:ok, args}

  def connection(status, state) do
    Logger.info("MQTT conexão: #{inspect(status)}")
    {:ok, state}
  end

  def handle_message(["sensores", "estufa"], payload, state) do
    Logger.info("Mensagem recebida: #{payload}")
    {:ok, state}
  end

  def handle_message(topic, payload, state) do
    Logger.info("Mensagem recebida em #{Enum.join(topic, "/")}: #{payload}")
    {:ok, state}
  end

  def subscription(status, topic, state) do
    Logger.info("Subscrição #{inspect(status)} no tópico #{inspect(topic)}")
    {:ok, state}
  end

  def terminate(_reason, _state), do: :ok
end
