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
         "temperatura" => temperatura,
         "umidade_ar" => umidade_ar,
         "umidade_solo" => umidade_solo,
         "luminosidade" => luminosidade,
         "status_bomba" => status_bomba,
         "status_luz" => status_luz,
         "data_hora" => data_hora
       }} ->
        Logger.info(
          "Valores -> Temp: #{temperatura}, Umidade Ar: #{umidade_ar}, Umidade Solo: #{umidade_solo}, Luminosidade: #{luminosidade}, Status da luz: #{status_luz}, Status da bomba: #{status_bomba}, Data e Hora: #{data_hora}"
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
