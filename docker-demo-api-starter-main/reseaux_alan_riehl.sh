#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DB_INIT_SQL="$SCRIPT_DIR/db/init.sql"
if command -v cygpath >/dev/null 2>&1; then
  DB_INIT_SQL="$(cygpath -w "$DB_INIT_SQL")"
fi

cleanup() {
  docker rm -f demo-api demo-db >/dev/null 2>&1 || true
  docker network rm demo_front demo_back >/dev/null 2>&1 || true
}
trap cleanup EXIT

wait_for_db() {
  local attempt
  for attempt in {1..60}; do
    if docker exec demo-db pg_isready -U demo >/dev/null 2>&1; then
      printf 'PostgreSQL est prêt (tentative %s).\n' "$attempt"
      return 0
    fi
    sleep 1
  done

  docker logs demo-db
  printf 'PostgreSQL ne répond pas après 60 secondes.\n' >&2
  return 1
}

wait_for_api() {
  local attempt
  for attempt in {1..30}; do
    if curl -fsS http://localhost:8080/ready >/dev/null 2>&1; then
      printf 'API prête et connectée à PostgreSQL.\n'
      return 0
    fi
    sleep 1
  done

  docker logs demo-api
  printf "L'API ne devient pas prête après 30 secondes.\n" >&2
  return 1
}

# Supprime les ressources laissées par une exécution précédente.
docker rm -f demo-api demo-db >/dev/null 2>&1 || true
docker network rm demo_front demo_back >/dev/null 2>&1 || true

docker build -t demo-api:1.0 "$SCRIPT_DIR/api"
docker network create demo_front
docker network create demo_back

MSYS_NO_PATHCONV=1 docker run -d \
  --name demo-db \
  --network demo_back \
  --mount "type=bind,source=$DB_INIT_SQL,target=/docker-entrypoint-initdb.d/init.sql,readonly" \
  -e POSTGRES_USER=demo \
  -e POSTGRES_PASSWORD=demo \
  -e POSTGRES_DB=demo \
  postgres:16-alpine

wait_for_db

docker run -d \
  --name demo-api \
  --network demo_front \
  -p 8080:3000 \
  -e PGHOST=demo-db \
  -e PGUSER=demo \
  -e PGPASSWORD=demo \
  -e PGDATABASE=demo \
  demo-api:1.0
docker network connect demo_back demo-api

wait_for_api

printf '\nRésolution de demo-db depuis demo-api :\n'
docker exec demo-api getent hosts demo-db

printf '\nTest depuis un conteneur tiers sur demo_front uniquement (échec attendu) :\n'
if docker run --rm --network demo_front alpine nc -zv demo-db 5432; then
  printf 'Échec du test d’isolation : le conteneur tiers a joint demo-db.\n' >&2
  exit 1
else
  printf 'Isolation confirmée : le conteneur tiers sur demo_front ne joint pas demo-db.\n'
fi

printf '\nAdresses IPv4 de demo-db par réseau :\n'
docker inspect -f '{{range $name, $network := .NetworkSettings.Networks}}{{$name}}: {{$network.IPAddress}}{{"\n"}}{{end}}' demo-db

printf 'Adresses IPv4 de demo-api par réseau :\n'
docker inspect -f '{{range $name, $network := .NetworkSettings.Networks}}{{$name}}: {{$network.IPAddress}}{{"\n"}}{{end}}' demo-api

printf 'Ports publiés par demo-db (aucun attendu) :\n'
docker port demo-db

printf '\nGET /products :\n'
curl -sS -f http://localhost:8080/products
printf '\n'
