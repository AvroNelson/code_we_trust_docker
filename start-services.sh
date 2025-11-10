#!/bin/bash
set -e

echo "[$(date)] Starting services..."

# Find PostgreSQL version
PG_VERSION=$(ls /usr/lib/postgresql/ | head -n1)
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"

# Start PostgreSQL
echo "[$(date)] Initializing PostgreSQL (version ${PG_VERSION})..."
if [ ! -f "${PGDATA}/PG_VERSION" ]; then
    echo "[$(date)] Initializing PostgreSQL database..."
    su - postgres -c "${PG_BIN}/initdb -D ${PGDATA}"

    # Start PostgreSQL temporarily to create database and user
    su - postgres -c "${PG_BIN}/pg_ctl -D ${PGDATA} -w start"

    # Create database and configure
    su - postgres -c "psql -c \"ALTER USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';\""
    su - postgres -c "psql -c \"CREATE DATABASE \\\"${POSTGRES_DB}\\\";\""

    # Stop PostgreSQL
    su - postgres -c "${PG_BIN}/pg_ctl -D ${PGDATA} -m fast -w stop"

    # Configure PostgreSQL to listen on all interfaces
    echo "host all all 0.0.0.0/0 md5" >> ${PGDATA}/pg_hba.conf
    echo "listen_addresses = '*'" >> ${PGDATA}/postgresql.conf
fi

# Start PostgreSQL in background
echo "[$(date)] Starting PostgreSQL..."
su - postgres -c "${PG_BIN}/pg_ctl -D ${PGDATA} -l ${PGDATA}/postgresql.log start"

# Wait for PostgreSQL to be ready
echo "[$(date)] Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if su - postgres -c "pg_isready -q"; then
        echo "[$(date)] PostgreSQL is ready"
        break
    fi
    echo "[$(date)] Waiting for PostgreSQL... ($i/30)"
    sleep 1
done

# Start Docker daemon (from cruizba/ubuntu-dind)
echo "[$(date)] Starting Docker daemon..."
/usr/local/bin/start-docker.sh &

# Wait for Docker to be ready
echo "[$(date)] Waiting for Docker to be ready..."
for i in {1..30}; do
    if docker info > /dev/null 2>&1; then
        echo "[$(date)] Docker is ready"
        break
    fi
    echo "[$(date)] Waiting for Docker... ($i/30)"
    sleep 1
done

# Set connection string for Code We Trust
export ConnectionStrings__CodeWeTrustDb="server=localhost;uid=${POSTGRES_USER};pwd=${POSTGRES_PASSWORD};database=${POSTGRES_DB};port=5432"
export AuthorizationSettings__Administrators="${CWT_ADMINISTRATORS:-*}"
export CodeWeTrustSettings__SkipBrowserOpen="true"
export ASPNETCORE_URLS="http://0.0.0.0:8080"

# Start Code We Trust
echo "[$(date)] Starting Code We Trust..."
cd /app
exec ./CodeWeTrust
