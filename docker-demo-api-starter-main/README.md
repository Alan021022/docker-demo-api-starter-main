# demo-api

Le fil rouge des quêtes Docker : une mini-API "catalogue" que tu vas
conteneuriser, faire persister, mettre en réseau, orchestrer et sécuriser,
une quête à la fois.

Le métier est volontairement trivial (`Node` + `Express` + `PostgreSQL`,
un catalogue de produits) : toute la difficulté est sur **Docker**, jamais
sur le code applicatif.

## Point de départ

Ce dossier est ce que tu clones **avant ta première quête Docker**. Il n'y a
volontairement **aucun fichier Docker** dedans, ni `Dockerfile`, ni
`compose.yml` : ce sont précisément les fichiers que tu vas écrire, quête
après quête, en faisant grossir ce dépôt.

Sans conteneur, cette API ne démarre pas telle quelle : elle a besoin d'un
PostgreSQL joignable pour répondre. C'est normal, et c'est tout le sujet de
la première quête que de la faire tourner dans Docker.

## Récupérer ce starter dans ton propre repo

Ce dépôt est un **starter en lecture seule** : tu ne pousses jamais
directement ici. Avant de démarrer la première quête :

1. **Clone** ce repo starter :
   ```bash
   git clone git@github.com:ynov-x-anthony/docker-demo-api-starter.git NOM_prenom_demo-api
   cd NOM_prenom_demo-api
   ```
2. **Supprime le remote `origin`** (il pointe vers le starter, pas vers toi) :
   ```bash
   git remote remove origin
   ```
3. **Crée ton propre repo** sur GitHub, dans l'organisation `ynov-x-anthony`,
   en respectant la nomenclature **`NOM_prenom_demo-api`** (ex. :
   `DUPONT_jean_demo-api`), puis ajoute-le comme nouveau remote et pousse :
   ```bash
   git remote add origin git@github.com:ynov-x-anthony/NOM_prenom_demo-api.git
   git push -u origin main
   ```

À partir de là, c'est **ton** repo : chaque quête s'y ajoute par des commits,
et c'est lui qui sera évalué, pas le starter.

## Ce que contient le repo

| Fichier | Rôle |
|---|---|
| `api/server.js` | l'API Express (`/`, `/version`, `/health`, `/ready`, `/products`) |
| `api/db.js` | connexion PostgreSQL, entièrement pilotée par des variables d'environnement |
| `api/package.json`, `api/package-lock.json` | dépendances (`express`, `pg`) |
| `db/init.sql` | création de la table `products` + quelques données de démo |

## Les routes de l'API

| Méthode | Route | Effet |
|---|---|---|
| `GET` | `/` | infos application + version |
| `GET` | `/version` | numéro de version courant |
| `GET` | `/health` | liveness, ne touche pas la base |
| `GET` | `/ready` | readiness, teste la connexion à la base |
| `GET` | `/products` | liste des produits |
| `POST` | `/products` | crée un produit : `{ "name": "...", "price_cents": 1234 }` |

## Ta progression, quête après quête

| Quête | Ce que tu ajoutes au repo |
|---|---|
| Découverte de Docker | rien ici, tu manipules des images publiques et un `psql` en conteneur |
| Le Dockerfile | `api/Dockerfile`, `api/.dockerignore` : l'API tourne enfin dans un conteneur |
| Les volumes | un volume nommé pour la persistance de PostgreSQL |
| Les réseaux | des réseaux dédiés, la base jamais exposée directement |
| Compose | `compose.yml`, `.env.example` : tous les services démarrent ensemble |
| Dockerfile et sécurité | ton `Dockerfile` durci : utilisateur non-root, `HEALTHCHECK` |
| Builds multi-étapes et gestion des secrets | `api/Dockerfile.multi` : image allégée, secrets hors de l'image |
| Analyse de vulnérabilité avec Trivy | un pipeline CI qui scanne ton image et bloque sur les failles critiques |

## Prérequis machine (macOS / Linux / Windows)

- **Docker Engine + Compose v2** : le plugin intégré, invoqué en deux mots
  `docker compose` (pas l'ancien binaire autonome `docker-compose` v1).
  `docker compose version` doit répondre `v2.x` ou une version supérieure
  (v3, v4, v5…). Ce qui compte, c'est que ce ne soit pas du v1 legacy.
- macOS / Windows : **Docker Desktop** (ou Colima / Rancher Desktop).
  Sous Windows, backend **WSL 2** : travaille depuis un terminal **WSL**.
- `git`, `curl`. Node est nécessaire **seulement** si tu régénères
  `package-lock.json` (`cd api && npm install`, déjà commité ici).
