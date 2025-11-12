defmodule MqttClient.Handler do
  @behaviour Tortoise311.Handler
  require Logger

  @impl true
  def init(_opts), do: {:ok, %{}}

  @impl true
  def connection(status, state) do
    Logger.info("🔌 Conexão MQTT mudou de status: #{inspect(status)}")
    {:ok, state}
  end

  @impl true
  def subscription(status, topic_filter, state) do
    Logger.info("📡 Subscrição #{inspect(topic_filter)} mudou para: #{inspect(status)}")
    {:ok, state}
  end

  @impl true
  def handle_message(topic, payload, state) do
    Logger.info("📩 Mensagem recebida no tópico #{topic}: #{payload}")

    case Jason.decode(payload) do
      {:ok, dados} ->
        # Salva os dados recebidos para o script Python
        temp_json = "/tmp/dados_sensor.json"
        File.write!(temp_json, Jason.encode!(dados, pretty: true))

        Logger.info("🤖 Executando modelo IA (scripts/predict.py)...")

        script_path = Path.expand("script/predict.py", File.cwd!())

        {output, exit_code} =
          System.cmd("python3", [script_path, temp_json], stderr_to_stdout: true)

        if exit_code == 0 do
          Logger.info("✅ IA executada com sucesso")
          Logger.debug("Saída do Python:\n#{output}")
        else
          Logger.error("❌ Erro ao executar IA:\n#{output}")
        end

        # Interpreta a saída da IA
        ia_result = String.trim(output)

        status_bomba =
          case ia_result do
            "LIGAR_BOMBA" -> "Bomba ativada"
            "DESLIGAR_BOMBA" -> "Bomba desativada"
            _ -> "Indefinido"
          end

        # Adiciona o campo no JSON que será enviado
        dados_atualizados = Map.put(dados, "status_bomba", status_bomba)

        # Envia para o backend em uma Task assíncrona
        Task.start(fn ->
          case HTTPoison.post(
                 "https://miniestufa-backend.onrender.com/api/sensor/push",
                 Jason.encode!(dados_atualizados),
                 [{"Content-Type", "application/json"}]
               ) do
            {:ok, %HTTPoison.Response{status_code: 200}} ->
              Logger.info("✅ Dados enviados com sucesso para o backend")

            {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
              Logger.warn("⚠️ Falha ao enviar (#{code}): #{body}")

            {:error, reason} ->
              Logger.error("❌ Erro HTTP: #{inspect(reason)}")
          end
        end)

        Logger.info("🚀 JSON enviado com status_bomba: #{inspect(dados_atualizados)}")

      {:error, reason} ->
        Logger.error("⚠️ Erro ao decodificar JSON: #{inspect(reason)}")
    end

    {:ok, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.warn("💀 Handler terminado: #{inspect(reason)}")
    {:ok, state}
  end
end
