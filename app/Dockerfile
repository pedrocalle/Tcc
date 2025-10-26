FROM elixir:1.17

RUN mkdir -p /app
WORKDIR /app

COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix compile
