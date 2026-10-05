#!/bin/bash
set -e

# PostgreSQL entrypoint initialization script for n8n
# Creates dedicated non-root user and grants privileges if defined

if [ -n "${POSTGRES_NON_ROOT_USER:-}" ] && [ -n "${POSTGRES_NON_ROOT_PASSWORD:-}" ]; then
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
		CREATE USER "${POSTGRES_NON_ROOT_USER}" WITH PASSWORD '${POSTGRES_NON_ROOT_PASSWORD}';
		GRANT ALL PRIVILEGES ON DATABASE "${POSTGRES_DB}" TO "${POSTGRES_NON_ROOT_USER}";
		GRANT ALL ON SCHEMA public TO "${POSTGRES_NON_ROOT_USER}";
		ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "${POSTGRES_NON_ROOT_USER}";
		ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "${POSTGRES_NON_ROOT_USER}";
	EOSQL
	echo "PostgreSQL setup: Non-root user '${POSTGRES_NON_ROOT_USER}' created with permissions on database '${POSTGRES_DB}'."
else
	echo "PostgreSQL setup: No non-root credentials specified, skipping non-root user creation."
fi
