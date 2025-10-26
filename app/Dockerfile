FROM elixir:1.16-alpine

WORKDIR /app

RUN apk add --no-cache build-base git

COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix compile

CMD ["mix", "run", "--no-halt"]
