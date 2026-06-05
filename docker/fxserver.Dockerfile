# FiveM server image — custom debug build overlaid on official proot structure.
# FXSERVER_VERSION provides the Alpine proot environment (musl, V8, mono).
# The debug binaries from your local build replace the official server binaries.
FROM debian:bookworm-slim

ARG FXSERVER_VERSION
RUN test -n "$FXSERVER_VERSION" || { \
      echo "ERROR: FXSERVER_VERSION build-arg is required."; \
      echo "See https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"; \
      exit 1; \
    }

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl xz-utils python3 \
 && rm -rf /var/lib/apt/lists/*

# Download official release for the full Alpine proot structure (musl, V8, mono, run.sh).
WORKDIR /opt/cfx-server
RUN curl -fSL "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${FXSERVER_VERSION}/fx.tar.xz" -o /tmp/fx.tar.xz \
 && tar -xJf /tmp/fx.tar.xz -C /opt/cfx-server \
 && rm /tmp/fx.tar.xz

# Overlay the custom debug binaries (FXServer, *.so, *.json, citizen/) on top.
RUN curl -fSL "http://192.168.1.252/fxserver/cfx-server-debug.tar.gz" -o /tmp/debug.tar.gz \
 && tar -xf /tmp/debug.tar.gz -C /opt/cfx-server/alpine/opt/cfx-server \
 && rm /tmp/debug.tar.gz

# Remove the release-build svadhesive — it is ABI-incompatible with debug binaries.
# Mirrors what wsl-build.sh does when libsvadhesive.so is absent.
RUN CFX=/opt/cfx-server/alpine/opt/cfx-server \
 && rm -f "$CFX/libsvadhesive.so" "$CFX/libsvadhesive.json" \
 && python3 -c "
import json, sys
path = '$CFX/components.json'
with open(path) as f:
    data = json.load(f)
def drop(v):
    if isinstance(v, list):
        return [x for x in v if 'svadhesive' not in str(x)]
    return v
if isinstance(data, list):
    data = drop(data)
elif isinstance(data, dict):
    data = {k: drop(v) for k, v in data.items()}
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
"

# server.cfg + resources/ are bind-mounted here by docker-compose at runtime.
WORKDIR /server-data
EXPOSE 30120/tcp
EXPOSE 30120/udp
EXPOSE 40120/tcp

CMD ["bash", "-c", "exec /opt/cfx-server/run.sh"]
