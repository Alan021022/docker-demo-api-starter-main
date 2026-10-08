# demo-api

Copie `.env.example` vers `.env`, puis démarre les services depuis la racine du
projet :

```bash
cp .env.example .env
docker compose up -d --build
```

Commande de démarrage testée : `docker compose up -d --build`.

Extrait de `docker compose ps` après le démarrage :

```text
NAME                                     SERVICE   STATUS
docker-demo-api-starter-main-adminer-1   adminer   Up
docker-demo-api-starter-main-api-1       api       Up (healthy)
docker-demo-api-starter-main-db-1        db        Up (healthy)
```

L'API est disponible sur <http://localhost:8080> et Adminer sur
<http://localhost:8081>. Pour arrêter les services, lance `docker compose down`.
