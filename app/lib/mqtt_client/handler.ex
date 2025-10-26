defmodule MqttClient.Handler do
  @behaviour Tortoise311.Handler
  require Logger

  @impl true
  def init(_opts), do: {:ok, %{}}

  @impl true
  def connection(status, state) do
    Logger.info("Conexão MQTT mudou de status: #{inspect(status)}")
    {:ok, state}
  end

  @impl true
  def handle_message(topic, payload, state) do
    Logger.info("Mensagem recebida no tópico #{topic}: #{payload}")

    case Jason.decode(payload) do
      {:ok,
       %{
         "temp" => temp,
         "umidade_ar" => umidade_ar,
         "umidade_solo" => umidade_solo,
         "luminosidade" => luminosidade
       }} ->
        Logger.info(
          "Valores -> Temp: #{temp}, Umidade Ar: #{umidade_ar}, Umidade Solo: #{umidade_solo}, Luminosidade: #{luminosidade}"
        )

      _ ->
        Logger.warn("Mensagem com formato inesperado")
    end

    {:ok, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.warn("Handler terminado: #{inspect(reason)}")
    {:ok, state}
  end
end
