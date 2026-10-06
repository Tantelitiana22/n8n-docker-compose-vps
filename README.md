# n8n Server

Stack Docker Compose pour héberger [n8n](https://n8n.io) en auto-hébergement, avec PostgreSQL, un task runner externe, l'assistant IA (sandbox) et la recherche web via SearXNG.

## Services

| Service | Rôle |
| --- | --- |
| `postgres` | Base de données PostgreSQL (persistante) |
| `n8n` | Moteur d'automatisation et interface web |
| `n8n-runner` | Task runner externe pour les nœuds Code (JS / Python) |
| `sandbox-certs`, `sandbox-api`, `sandbox-runner-1` | Sandbox de l'assistant IA n8n (mTLS) |
| `searxng` | Méta-moteur de recherche utilisé par l'assistant IA |

## Prérequis

- Docker et Docker Compose v2
- Une clé API [OpenRouter](https://openrouter.ai) pour l'assistant IA (optionnel)

> [!NOTE]
> `sandbox-runner-1` tourne en mode `privileged` (Docker-in-Docker). À n'utiliser que sur un hôte de confiance.

## Configuration

Copier le fichier d'exemple, puis adapter les valeurs :

```bash
cp .env.example .env
```

> [!WARNING]
> Les valeurs de `.env.example` sont des exemples. Générer vos propres secrets avant tout usage réel, et ne jamais commiter `.env`.

Générer un secret aléatoire :

```bash
openssl rand -hex 24
```

### Variables à définir

**Réseau et version**

| Variable | Défaut | Description |
| --- | --- | --- |
| `N8N_VERSION` | `latest` | Version de l'image n8n et des runners |
| `N8N_PORT` | `5678` | Port exposé sur l'hôte |
| `N8N_PROTOCOL` | `http` | `http` ou `https` |
| `N8N_HOST` | `localhost` | Nom d'hôte public de n8n |
| `WEBHOOK_URL` | `http://localhost:5678/` | URL publique utilisée pour les webhooks |
| `GENERIC_TIMEZONE`, `TZ` | `UTC` | Fuseau horaire (ex. `Europe/Paris`) |

**Secrets obligatoires**

| Variable | Description |
| --- | --- |
| `N8N_ENCRYPTION_KEY` | Clé de chiffrement des credentials. À conserver : sans elle, les credentials existants sont illisibles |
| `RUNNERS_AUTH_TOKEN` | Jeton d'authentification entre `n8n` et `n8n-runner` |
| `SANDBOX_API_KEY` | Clé API partagée entre `n8n` et `sandbox-api` |
| `SANDBOX_API_RUNNER_REGISTRATION_TOKEN` | Jeton d'enregistrement du runner de sandbox |
| `SANDBOX_API_RUNNER_API_KEY` | Clé API du runner de sandbox |
| `SEARXNG_SECRET` | Secret SearXNG (par défaut : `RUNNERS_AUTH_TOKEN`) |

**PostgreSQL**

| Variable | Description |
| --- | --- |
| `POSTGRES_VERSION` | Version de l'image (défaut `16-alpine`) |
| `POSTGRES_DB` | Nom de la base |
| `POSTGRES_USER`, `POSTGRES_PASSWORD` | Compte administrateur |
| `POSTGRES_NON_ROOT_USER`, `POSTGRES_NON_ROOT_PASSWORD` | Compte utilisé par n8n, créé par [init-data.sh](init-data.sh) |

**Assistant IA (optionnel)**

| Variable | Description |
| --- | --- |
| `N8N_INSTANCE_AI_MODEL` | Modèle utilisé (ex. `openrouter/openai/gpt-5.6-luna`) |
| `N8N_INSTANCE_AI_MODEL_API_KEY` | Clé API du modèle |
| `OPENROUTER_API_KEY` | Clé API OpenRouter |

**Compte propriétaire n8n**

Le compte administrateur est créé automatiquement depuis l'environnement.

| Variable | Description |
| --- | --- |
| `N8N_INSTANCE_OWNER_MANAGED_BY_ENV` | `true` pour gérer le compte via l'environnement |
| `N8N_INSTANCE_OWNER_EMAIL` | Email de connexion |
| `N8N_INSTANCE_OWNER_FIRST_NAME`, `N8N_INSTANCE_OWNER_LAST_NAME` | Prénom et nom |
| `N8N_INSTANCE_OWNER_PASSWORD_HASH` | Hash bcrypt du mot de passe |

Générer le hash bcrypt du mot de passe :

```bash
docker run --rm httpd:alpine htpasswd -nbBC 10 "" 'MonMotDePasse' | tr -d ':\n' | sed 's/$2y/$2a/'
```

> [!IMPORTANT]
> Dans `.env`, chaque `$` du hash doit être doublé (`$$`) pour éviter l'interpolation par Docker Compose, par exemple `$$2a$$10$$...`.

## Lancer

```bash
docker compose up -d
```

Suivre les logs et vérifier l'état :

```bash
docker compose ps
docker compose logs -f n8n
```

Arrêter la stack :

```bash
docker compose down        # conserve les données
docker compose down -v     # supprime aussi les volumes (données perdues)
```

## Accéder à n8n

Ouvrir [http://localhost:5678](http://localhost:5678) (ou le port défini dans `N8N_PORT`) et se connecter avec `N8N_INSTANCE_OWNER_EMAIL` et le mot de passe correspondant au hash défini dans `N8N_INSTANCE_OWNER_PASSWORD_HASH`.

Pour un accès depuis un autre domaine, adapter `N8N_HOST`, `N8N_PROTOCOL` et `WEBHOOK_URL` (idéalement derrière un reverse proxy HTTPS).

## Mise à jour

```bash
docker compose pull
docker compose up -d
```

## Données persistantes

| Volume | Contenu |
| --- | --- |
| `db_storage` | Données PostgreSQL |
| `n8n_storage` | Données n8n (`/home/node/.n8n`) |
| `sandbox-tls` | Certificats mTLS de la sandbox |
| `sandbox_runner_data` | Données Docker du runner de sandbox |
