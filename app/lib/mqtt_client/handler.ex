defmodule MqttClient.Handler do
  @behaviour Tortoise311.Handler
  require Logger

  @backend_url "https://miniestufa-backend.onrender.com"

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
  def handle_message(topic, payload, state) do
    Logger.info("💬 Mensagem recebida no tópico #{topic}: #{payload}")

    case Jason.decode(payload) do
      {:ok, dados} ->
        Logger.info("""
        🌡️ Dados recebidos:
          Tipo: #{dados["tipo"]}
          Temperatura: #{dados["temperatura"]}
          Umidade do Ar: #{dados["umidade_ar"]}
          Umidade do Solo: #{dados["umidade_solo"]}
          Luminosidade: #{dados["luminosidade"]}
          Solo (bruto): #{dados["solo_bruto"]}
          Status Bomba: #{dados["status_bomba"]}
          Status Luz: #{dados["status_luz"]}
          Data/Hora: #{dados["data_hora"]}
        """)

        Task.start(fn -> forward_to_backend(dados, payload) end)

      {:error, reason} ->
        Logger.warn("⚠️ Falha ao decodificar JSON: #{inspect(reason)} | payload=#{payload}")
    end

    {:ok, state}
  end

  defp forward_to_backend(dados, raw_payload) do
    body_map =
      dados
      |> Map.take([
        "tipo",
        "data_hora",
        "temperatura",
        "umidade_ar",
        "luminosidade",
        "umidade_solo",
        "solo_bruto",
        "status_bomba",
        "status_luz"
      ])
      |> Map.reject(fn {_, v} -> is_nil(v) end)

    case Jason.encode(body_map) do
      {:ok, body} ->
          Logger.info("🚀 Enviando JSON: #{body}")

          case HTTPoison.post(
               "#{@backend_url}/api/sensor/push",
                 body,
                 [{"Content-Type", "application/json"}]
               ) do
            {:ok, %HTTPoison.Response{status_code: 200}} ->
              Logger.info("✅ Dados enviados com sucesso para o backend")

            {:ok, %HTTPoison.Response{status_code: code, body: resp_body}} ->
            Logger.warn("⚠️ Falha ao enviar (#{code}): #{inspect(resp_body)} | payload=#{body}")

            {:error, reason} ->
            Logger.error("❌ Erro HTTP: #{inspect(reason)} | body=#{body}")
          end

      {:error, reason} ->
        Logger.error("❌ Não foi possível serializar JSON: #{inspect(reason)} | dados=#{inspect(body_map)} | payload=#{raw_payload}")
    end
  end

  @impl true
  def terminate(reason, state) do
    Logger.warn("🚨 Handler terminado: #{inspect(reason)}")
    {:ok, state}
  end
end
