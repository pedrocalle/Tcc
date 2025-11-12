import joblib
import pandas as pd
from datetime import datetime
import os
import sys
import json
import paho.mqtt.client as mqtt

# Caminhos
models_dir = "models"
os.makedirs(models_dir, exist_ok=True)
model_path = os.path.join(models_dir, "modelo_estufa.pkl")
features_path = os.path.join(models_dir, "features.joblib")

# Histórico
historico_dir = "historico"
os.makedirs(historico_dir, exist_ok=True)
historico_csv = os.path.join(historico_dir, "historico_estufa.csv")

# Configuração MQTT
BROKER = os.getenv("MQTT_HOST", "mosquitto") 
TOPIC = "estufa/controle"
client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
client.connect(BROKER, 1883, 60)

# Carrega modelo e features
model = joblib.load(model_path)
features = joblib.load(features_path)

# --- 🔹 Lê o JSON recebido do Elixir ---
if len(sys.argv) < 2:
    print("Erro: caminho do JSON não fornecido")
    sys.exit(1)

json_path = sys.argv[1]

with open(json_path, "r") as f:
    dados_sensor = json.load(f)

# --- 🔹 Mapeia para os nomes esperados pelo modelo ---
df = pd.DataFrame([{
    "Ambient_Temperature": dados_sensor.get("temperatura"),
    "Humidity": dados_sensor.get("umidade_ar"),
    "Light_Intensity": dados_sensor.get("luminosidade"),
    "Soil_Moisture": dados_sensor.get("umidade_solo"),
    "created": datetime.now()
}])

# --- 🔹 Predição ---
y_pred = model.predict(df[features])[0]
regar_por_modelo = bool(y_pred)

umidade_solo = df["Soil_Moisture"][0]
regar_por_regra = umidade_solo < 30

regar = regar_por_modelo or regar_por_regra

if regar:
    decisao = "Regar agora"
    comando = "LIGAR_BOMBA"
else:
    decisao = "Não regar"
    comando = "DESLIGAR_BOMBA"

# --- 🔹 Publica no MQTT ---
client.publish(TOPIC, comando)
print(comando)

# --- 🔹 Salva histórico ---
df.assign(prediction=decisao).to_csv(historico_csv, mode="a", header=not os.path.exists(historico_csv), index=False)
