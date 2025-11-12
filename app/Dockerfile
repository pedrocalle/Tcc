FROM elixir:1.17

# Instalar Python 3 e pip
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# Criar e ativar ambiente virtual Python para IA
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Instalar dependências da IA
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

# Instalar dependências do Elixir
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix compile

CMD ["mix", "run", "--no-halt"]
