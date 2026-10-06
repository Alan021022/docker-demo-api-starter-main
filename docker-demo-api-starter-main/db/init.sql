-- Joue UNE SEULE FOIS, au tout premier demarrage de PostgreSQL, quand le
-- repertoire de donnees est vide (mecanisme /docker-entrypoint-initdb.d de
-- l'image officielle postgres). Si le volume pgdata existe deja, ce fichier
-- est ignore.

CREATE TABLE IF NOT EXISTS products (
  id          SERIAL PRIMARY KEY,
  name        TEXT        NOT NULL,
  price_cents INTEGER     NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO products (name, price_cents) VALUES
  ('Sticker Demo',        150),
  ('Mug Docker',            990),
  ('T-shirt conteneur',    1990);
