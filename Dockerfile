FROM elixir:1.7

# Install Hex+Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

WORKDIR /opt/app

ENV MIX_ENV=prod

# Cache elixir deps
ADD . .
RUN mix deps.get
RUN mix release

# Use REPLACE_OS_VARS=true in order to swap runtime env values in rel/vm.args
ENV REPLACE_OS_VARS=true

# Do not use CMD, leads to issues receiving SIGTERM properly
ENTRYPOINT ["_build/prod/rel/ex_cluster/bin/ex_cluster", "foreground"]