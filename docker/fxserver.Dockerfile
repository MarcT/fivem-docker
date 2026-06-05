# FiveM server image — custom build.
FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

# Download + extract the custom server artifacts into /opt/cfx-server.
WORKDIR /opt/cfx-server
RUN curl -fSL "http://192.168.1.252/fxserver/cfx-server-debug.tar.gz" -o /tmp/fx.tar.gz \
 && tar -xzf /tmp/fx.tar.gz -C /opt/cfx-server \
 && rm /tmp/fx.tar.gz

# server.cfg + resources/ are bind-mounted here by docker-compose at runtime.
WORKDIR /server-data
EXPOSE 30120/tcp
EXPOSE 30120/udp
EXPOSE 40120/tcp

# No "+exec server.cfg" → run.sh boots txAdmin, which manages the game server.
CMD ["bash", "-c", "exec /opt/cfx-server/run.sh"]
