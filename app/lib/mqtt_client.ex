defmodule MqttClient do
  use GenServer
  require Logger

  @topic "sensores/estufa"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    host = System.get_env("MQTT_HOST", "mosquitto")
    port = String.to_integer(System.get_env("MQTT_PORT", "1883"))

    Logger.info("Conectando ao broker MQTT em #{host}:#{port}")

    {:ok, _pid} =
      Tortoise311.Connection.start_link(
        client_id: "tcc_app_client",
        server: {Tortoise311.Transport.Tcp, host: host, port: port},
        handler: {MqttClient.Handler, []},
        subscriptions: [{@topic, 0}]
      )

    {:ok, %{}}
  end

  # Publicar todas as 4 variáveis
  def publish(temp, umidade_ar, umidade_solo, luminosidade) do
    payload =
      %{
        temp: temp,
        umidade_ar: umidade_ar,
        umidade_solo: umidade_solo,
        luminosidade: luminosidade
      }
      |> Jason.encode!()

    case Tortoise311.publish("tcc_app_client", @topic, payload, qos: 0) do
      :ok ->
        Logger.info("Mensagem publicada: #{payload}")
        :ok

      {:error, reason} ->
        Logger.error("Erro ao publicar mensagem: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
