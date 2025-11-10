# Code We Trust Standalone Docker Image

Self-contained Docker image for running Code We Trust with embedded PostgreSQL and Docker-in-Docker for isolated code analysis.

## Quick Start

**Build the image:**
```bash
docker build --platform linux/amd64 -t codewetrust:standalone .
```

**Run the container:**
```bash
docker run -d \
  --name codewetrust \
  --privileged \
  --platform linux/amd64 \
  -p 8080:8080 \
  codewetrust:standalone
```

**Access the application:**
- Open http://localhost:8080 in your browser
- Login and use the web UI to run code analysis

**View logs:**
```bash
docker logs -f codewetrust
```

## What's Inside

This image includes:
- **Docker-in-Docker** (cruizba/ubuntu-dind) - For running isolated code analysis containers
- **PostgreSQL 16** - Embedded database for storing analysis results
- **Code We Trust 8.5.1.1** - Static code analysis application

The startup script orchestrates all three services automatically.

## Requirements

- Docker with `--privileged` flag support (required for Docker-in-Docker)
- Platform must support linux/amd64 (Code We Trust binaries are x86-64 only)
- 8 GB of available RAM required

### Environment Variables

You can override settings at runtime:

```bash
docker run -d \
  --name codewetrust \
  --privileged \
  --platform linux/amd64 \
  -p 8080:8080 \
  -e POSTGRES_PASSWORD=CustomPassword123 \
  codewetrust:standalone
```

Available variables:
- `POSTGRES_PASSWORD` - Database password (default: CwtP0stgres1)
- `POSTGRES_USER` - Database user (default: postgres)
- `POSTGRES_DB` - Database name (default: code-we-trust)

### Authorization

By default, all registered users have admin access (`Administrators: "*"`).

## Management Commands

### Start container
```bash
docker run -d --name codewetrust --privileged --platform linux/amd64 -p 8080:8080 codewetrust:standalone
```

### Stop container
```bash
docker stop codewetrust
```

### Remove container (keeps image)
```bash
docker rm codewetrust
```

### Remove container and data
```bash
docker rm -f codewetrust
```

### View logs
```bash
docker logs -f codewetrust
```

### Access PostgreSQL inside container
```bash
docker exec -it codewetrust su - postgres -c "psql -d code-we-trust"
```

### Rebuild image after configuration changes
```bash
docker build --platform linux/amd64 -t codewetrust:standalone .
```

## Troubleshooting

### Port conflicts
If port 8080 is already in use, map to a different port:
```bash
docker run -d --name codewetrust --privileged --platform linux/amd64 -p 8081:8080 codewetrust:standalone
```
Then access at http://localhost:8081

### Container exits immediately
Check logs for errors:
```bash
docker logs codewetrust
```

Common issues:
- Missing `--privileged` flag (required for Docker-in-Docker)
- Platform mismatch (must use `--platform linux/amd64`)
- Port 8080 already in use

### PostgreSQL connection issues
The startup script waits for PostgreSQL to be ready. If you see connection errors:
1. Check logs: `docker logs codewetrust`
2. Verify PostgreSQL started: Look for "PostgreSQL is ready" in logs
3. Wait 30 seconds after container start for all services to initialize

### Analysis jobs fail
Ensure the container has sufficient resources:
- 8 GB RAM required
- Docker-in-Docker requires `--privileged` flag

### Reset everything
```bash
docker rm -f codewetrust
docker rmi codewetrust:standalone
docker build --platform linux/amd64 -t codewetrust:standalone .
docker run -d --name codewetrust --privileged --platform linux/amd64 -p 8080:8080 codewetrust:standalone
```

## File Structure

```
.
├── Dockerfile           # Image definition
├── start-services.sh    # Service orchestration script
├── appsettings.json     # Application configuration
├── .env.example         # Environment template (optional reference)
├── .dockerignore        # Files to exclude from build
└── README.md           # This file
```

## Cloud Deployment

This image is designed for cloud deployment where you need:
- Self-contained, portable deployment
- Isolation of third-party code analysis
- No dependency on external services

**Example deployment:**
```bash
# On any cloud VM with Docker installed
docker build --platform linux/amd64 -t codewetrust:standalone .
docker run -d \
  --name codewetrust \
  --privileged \
  --platform linux/amd64 \
  -p 8080:8080 \
  -v codewetrust-data:/var/lib/postgresql/data \
  --restart unless-stopped \
  codewetrust:standalone
```

## Architecture

The startup sequence:
1. **PostgreSQL** initializes (first run only) and starts
2. **Docker daemon** starts (from cruizba/ubuntu-dind base)
3. **Code We Trust** launches and connects to localhost PostgreSQL

All services run inside a single container with proper initialization and health checking.

## Security Notes

- The container runs with `--privileged` flag, which is required for Docker-in-Docker
- Default PostgreSQL password is embedded in the image (change before deployment)
- By default, all registered users have admin access (configure authorization for production)
- Analysis runs in isolated Docker containers within the main container
