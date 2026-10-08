#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DB_INIT_SQL="$SCRIPT_DIR/db/init.sql"
if command -v cygpath >/dev/null 2>&1; then
  DB_INIT_SQL="$(cygpath -w "$DB_INIT_SQL")"
fi
NETWORK_NAME="demo-persistence-net"
VOLUME_NAME="demo_pgdata"

cleanup() {
  docker rm -f demo-api demo-db >/dev/null 2>&1 || true
  docker network rm "$NETWORK_NAME" >/dev/null 2>&1 || true
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

start_db() {
  MSYS_NO_PATHCONV=1 docker run -d \
    --name demo-db \
    --network "$NETWORK_NAME" \
    --mount "type=volume,source=$VOLUME_NAME,target=/var/lib/postgresql/data" \
    --mount "type=bind,source=$DB_INIT_SQL,target=/docker-entrypoint-initdb.d/init.sql,readonly" \
    -e POSTGRES_USER=demo \
    -e POSTGRES_PASSWORD=demo \
    -e POSTGRES_DB=demo \
    postgres:16-alpine
}

start_api() {
  docker run -d \
    --name demo-api \
    --network "$NETWORK_NAME" \
    -p 8080:3000 \
    -e PGHOST=demo-db \
    -e PGUSER=demo \
    -e PGPASSWORD=demo \
    -e PGDATABASE=demo \
    demo-api:1.0

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

# Retire les conteneurs/réseaux résiduels d'une exécution interrompue sans toucher au volume.
docker rm -f demo-api demo-db >/dev/null 2>&1 || true
docker network rm "$NETWORK_NAME" >/dev/null 2>&1 || true

docker build -t demo-api:1.0 "$SCRIPT_DIR/api"
docker volume create "$VOLUME_NAME"
docker network create "$NETWORK_NAME"

start_db

wait_for_db
start_api

printf '\nAjout du produit :\n'
POST_RESULT="$(curl -sS -w '\n%{http_code}' -X POST -H 'content-type: application/json' \
  -d '{"name":"Casquette D\u00e9mo","price_cents":1200}' \
  http://localhost:8080/products)"
POST_STATUS="${POST_RESULT##*$'\n'}"
POST_BODY="${POST_RESULT%$'\n'*}"
printf '%s\n' "$POST_BODY"
if [[ "$POST_STATUS" != "201" ]]; then
  printf 'Échec de l’ajout du produit (HTTP %s).\n' "$POST_STATUS" >&2
  exit 1
fi
printf '\n\nProduits avant la recréation de la base :\n'
curl -sS -f http://localhost:8080/products
printf '\n'

printf '\nSuppression du conteneur PostgreSQL et de l’API...\n'
docker rm -f demo-api demo-db

printf '\nRecréation de PostgreSQL avec le même volume...\n'
start_db

wait_for_db
start_api

printf '\nVérification de la persistance après recréation :\n'
PRODUCTS="$(curl -sS -f http://localhost:8080/products)"
printf '%s\n' "$PRODUCTS"
if ! grep -Fq 'Casquette Démo' <<<"$PRODUCTS"; then
  printf 'Échec : « Casquette Démo » est absent après recréation de la base.\n' >&2
  exit 1
fi
printf 'Succès : « Casquette Démo » a survécu à la recréation du conteneur.\n'

printf '\nVolume conservé :\n'
docker volume ls | grep "$VOLUME_NAME"
printf '\nGET /products final :\n'
curl -sS -f http://localhost:8080/products
printf '\n'

# Pour supprimer aussi les données persistées après la démonstration :
# docker volume rm demo_pgdata
