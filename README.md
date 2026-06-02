# fivem-docker

Dockerized FiveM setup: **FiveM server (txAdmin-managed) + PostgreSQL**, started entirely via
`docker compose`. No Redis, no build toolchain — just the Docker layer.

## What's inside

| Service     | Description |
| ----------- | ----------- |
| `fxserver`  | FiveM server from the official Linux artifacts. Boots into **txAdmin** by default — the game server is managed/started through the txAdmin web panel. |
| `postgres`  | PostgreSQL 16. Available to your resources via `DATABASE_URL` (not used by txAdmin itself). |

```
.
├── docker-compose.yml          # postgres + fxserver
├── docker/fxserver.Dockerfile  # downloads the FiveM Linux artifacts
├── .env.example                # configuration (copy to .env)
└── server-data/                # your server (bind-mounted into the container)
    ├── server.cfg              # managed by txAdmin
    └── resources/[local]/      # drop your resources here (e.g. crizzly)
```

## Quick start

```bash
cp .env.example .env            # 1. configure (set the password + FXSERVER_VERSION)
docker compose up -d --build    # 2. build + start everything
```

Then:

1. **Open txAdmin:** <http://localhost:40120>
2. On first run, create an **admin account**.
3. Choose the **"Local" / existing server data** deployment method and point it at `/server-data`
   — txAdmin will detect the `server.cfg`.
4. Enter your **Cfx.re license key** in txAdmin (from <https://portal.cfx.re>). txAdmin stores it in
   `txData`, **not** in `server.cfg`.
5. **Start** the server from txAdmin → it then runs on port **30120** (TCP/UDP).

> The game server (30120) only runs **after** you start it from txAdmin — that's normal txAdmin
> behavior. On the next `docker compose up`, txAdmin auto-starts the server thanks to the persistent
> `txData` volume.

## Configuration (`.env`)

| Variable           | Meaning |
| ------------------ | ------- |
| `FXSERVER_VERSION` | Build number of the FiveM Linux artifacts ([list](https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/)). Required. |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | PostgreSQL credentials. |
| `POSTGRES_PORT`    | Host port for Postgres (default 5432). |
| `DATABASE_URL`     | Connection string for host tools (psql/GUI). Inside Docker, `fxserver` gets its own `DATABASE_URL` with host `postgres`. |
| `TXADMIN_PORT`     | Host port for the txAdmin panel (default 40120). |
| `SERVER_PASSWORD`  | Optional connect password. |

## Your own resources

Put your resources under `server-data/resources/[local]/<name>/` and enable them with
`ensure <name>` in `server.cfg`. Changes are visible in the container immediately (bind mount) —
a resource `restart` via txAdmin or the server console is enough.

### Using PostgreSQL from a resource

The connection URL is provided as the container env var `DATABASE_URL`
(`postgresql://<user>:<pass>@postgres:5432/<db>`). Access it via:

- **JS server script:** `process.env.DATABASE_URL` (e.g. with the `pg` npm module).
- **Lua:** set the URL as a ConVar in `server.cfg` (`set database_url "..."`) and read it with
  `GetConvar('database_url', '')`.

> Note: most off-the-shelf resources (oxmysql, etc.) expect **MySQL/MariaDB**. This setup provides
> **PostgreSQL** — usable from your own resources that speak `pg`/Postgres.

## Platform support

The **same `docker compose up` works on Windows and Linux automatically** — Docker runs the
container as Linux/amd64 either way. Requirement: an **x86_64 (amd64)** host, since FiveM's server
is x86_64-only.

| Host                                  | Status                 | Notes |
| ------------------------------------- | ---------------------- | ----- |
| **Linux** x86_64 (VPS/server)         | ✅ works (recommended)  | Native, fastest, most stable. |
| **Windows** (x86_64) + Docker Desktop | ✅ works automatically  | `docker compose up` runs the amd64 Linux container in Docker's VM. |

Nothing to configure on either — the `platform: linux/amd64` pin in `docker-compose.yml` handles it.

## Useful commands

```bash
docker compose logs -f fxserver   # server logs
docker compose ps                 # status
docker compose down               # stop (volumes/data preserved)
docker compose down -v            # stop + delete ALL data (DB + txData)
docker compose up -d --build fxserver   # rebuild after changing FXSERVER_VERSION
```
