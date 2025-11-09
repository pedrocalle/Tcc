defmodule MqttClient.Handler do
  @behaviour Tortoise311.Handler
  require Logger

  @impl true
  def init(_opts) do
    Logger.info("🔌 Handler MQTT iniciado")
    {:ok, %{}}
  end

  @impl true
  def connection(status, state) do
    Logger.info("📡 Conexão MQTT mudou de status: #{inspect(status)}")
    {:ok, state}
  end

  @impl true
  def subscription(status, topic_filter, state) do
    Logger.info("📬 Subscrição #{inspect(topic_filter)} mudou para: #{inspect(status)}")
    {:ok, state}
  end

  @impl true
  @impl true
  def handle_message(topic, payload, state) do
    Logger.info("💬 Mensagem recebida no tópico #{topic}: #{payload}")

    case Jason.decode(payload) do
      {:ok, dados} ->
        Logger.info("""
        🌡️ Dados recebidos:
          Temperatura: #{dados["temperatura"]}
          Umidade do Ar: #{dados["umidade_ar"]}
          Umidade do Solo: #{dados["umidade_solo"]}
          Luminosidade: #{dados["luminosidade"]}
          Umidade Solo Bruto: #{dados["umidade_solo_bruto"]}
          Status Bomba: #{dados["status_bomba"]}
          Data/Hora: #{dados["data_hora"]}
        """)

        Task.start(fn ->
          body =
            %{
              "data_hora" => dados["data_hora"],
              "temperatura" => dados["temperatura"],
              "umidade_ar" => dados["umidade_ar"],
              "luminosidade" => dados["luminosidade"],
              "umidade_solo" => dados["umidade_solo"],
              "umidade_solo_bruto" => round(dados["umidade_solo_bruto"]),
              "status_bomba" => to_string(dados["status_bomba"])
            }
            |> Jason.encode!()

          Logger.info("🚀 Enviando JSON: #{body}")

          case HTTPoison.post(
                 "https://miniestufa-backend.onrender.com/api/sensor/push",
                 body,
                 [{"Content-Type", "application/json"}]
               ) do
            {:ok, %HTTPoison.Response{status_code: 200}} ->
              Logger.info("✅ Dados enviados com sucesso para o backend")

            {:ok, %HTTPoison.Response{status_code: code, body: resp_body}} ->
              Logger.warn("⚠️ Falha ao enviar (#{code}): #{inspect(resp_body)}")

            {:error, reason} ->
              Logger.error("❌ Erro HTTP: #{inspect(reason)}")
          end
        end)

      {:error, reason} ->
        Logger.warn("⚠️ Falha ao decodificar JSON: #{inspect(reason)}")
    end

    {:ok, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.warn("🚨 Handler terminado: #{inspect(reason)}")
    {:ok, state}
  end
end
