# AEM Docker Development Environment

## Project Overview

Docker-based local AEM development setup with Author, Publish, and Dispatcher services. Designed for AEM developers to quickly spin up a full AEM as a Cloud Service environment.

## Architecture

- **Author** (`author/Dockerfile`): AEM Author on port 4502, debug port 30303. Based on `eclipse-temurin:21-jdk`.
- **Publish** (`publish/Dockerfile`): AEM Publish on port 4503, debug port 30304. Based on `eclipse-temurin:21-jdk`.
- **Dispatcher** (pre-built SDK image `adobe/aem-cs/dispatcher-publish:2.0.235`): Apache + `mod_dispatcher` on port 80. Proxies to the publish instance.

## Key Files

- `.env` — ports, project name, `DISPATCHER_PATH` for client dispatcher configs
- `docker-compose.yml` — service orchestration
- `install/` — AEM JAR and CIF packages (git-ignored, must be placed manually)
- `dispatcher/dispatcher-sdk-2.0.235/` — extracted Adobe Dispatcher SDK

## Dispatcher

The dispatcher uses the **pre-built Adobe SDK Docker image**, not a custom build. The old `dispatcher/Dockerfile` is kept for reference but is no longer used.

- SDK config source is mounted at `/mnt/dev/src` inside the container
- Default: uses SDK defaults from `./dispatcher/dispatcher-sdk-2.0.235/src`
- Client project: set `DISPATCHER_PATH` in `.env` to the client's `dispatcher/src/` directory
- The entrypoint script (`import_sdk_config.sh`) merges customer config with SDK defaults

## Common Commands

```bash
# Start all services
docker compose up -d

# Start only specific service
docker compose up -d author

# Rebuild after Dockerfile changes
docker compose up -d --build

# Recreate dispatcher after config changes
docker compose up -d --force-recreate dispatcher

# View logs
docker compose logs -f dispatcher

# Reset everything (destroys all data)
docker compose down -v

# Load dispatcher image (first time only, arm64 Mac)
gunzip -c dispatcher/dispatcher-sdk-2.0.235/lib/dispatcher-publish-arm64.tar.gz | docker load

# Load dispatcher image (first time only, amd64)
gunzip -c dispatcher/dispatcher-sdk-2.0.235/lib/dispatcher-publish-amd64.tar.gz | docker load
```

## Conventions

- AEM instances use `-nofork` mode with remote debugging enabled by default
- Memory: 2048m heap + 512m metaspace per instance
- Docker volumes persist AEM repository data between restarts
- Use container names (e.g., `publish`, `author`) for inter-service communication, not `localhost`
- Replication agent URI: `http://publish:4503/bin/receive?sling:authRequestLogin=1`

## After `mvn clean install -PautoInstallPackage`

AEM takes ~2 minutes to restart OSGi bundles. This is normal. The dispatcher has `serveStaleOnError "1"` enabled, so it will serve cached content while AEM recovers.
