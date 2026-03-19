# AEM Docker Development Environment

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Adobe AEMaaCS](https://img.shields.io/badge/Adobe%20AEMaaCS-FF0000?style=for-the-badge&logo=adobe&logoColor=white)](https://business.adobe.com/products/experience-manager/adobe-experience-manager.html)
[![Apache](https://img.shields.io/badge/Apache-D22128?style=for-the-badge&logo=apache&logoColor=white)](https://httpd.apache.org/)

A Docker-based local development environment for Adobe Experience Manager as a Cloud Service (AEMaaCS) with Author, Publish, and Dispatcher.

## Architecture

| Service | Port | Debug Port | Description |
|---------|------|------------|-------------|
| Author | 4502 | 30303 | AEM Author instance |
| Publish | 4503 | 30304 | AEM Publish instance |
| Dispatcher | 8080 | - | Apache + mod_dispatcher (proxies to Publish) |

## Prerequisites

- Docker and Docker Compose
- AEM as a Cloud Service SDK (QuickStart JAR)
- CIF Feature Packages (if using Commerce)

## Setup

### Step 1: Clone and prepare files

```bash
git clone <repository-url>
cd aem-docker
```

Place the following licensed files in the `install/` directory:

| File | Required | Source |
|------|----------|--------|
| `aem-quickstart.jar` | Yes | Adobe Software Distribution |
| `cif-*-authorfar.far` | Yes | Adobe Software Distribution |
| `cif-*-publishfar.far` | Yes | Adobe Software Distribution |

The following packages are **pre-downloaded** in the `install/` directory and installed automatically on both Author and Publish:

| File | Version | Description |
|------|---------|-------------|
| `io.wcm.caconfig.editor.package-*.zip` | 1.16.10 | [wcm.io Context-Aware Configuration Editor](https://wcm.io/caconfig/editor/) UI |
| `io.wcm.caconfig.extensions-*.jar` | 1.11.0 | [wcm.io CAConfig Extensions](https://wcm.io/caconfig/extensions/) for Sling CAConfig |

> These packages are for **local development only**. For AEMaaCS (cloud), embed them in your project's Maven `all` package instead.

### Step 2: Load the Dispatcher Docker image

The Adobe Dispatcher SDK ships as a pre-built Docker image. You need to load it once:

**Apple Silicon (M1/M2/M3/M4):**
```bash
gunzip -c dispatcher/dispatcher-sdk-2.0.235/lib/dispatcher-publish-arm64.tar.gz | docker load
```

**Intel / AMD:**
```bash
gunzip -c dispatcher/dispatcher-sdk-2.0.235/lib/dispatcher-publish-amd64.tar.gz | docker load
```

You should see: `Loaded image: adobe/aem-cs/dispatcher-publish:2.0.235`

### Step 3: Configure environment

Copy the example `.env` or create your own:

```env
COMPOSE_PROJECT_NAME=aem

# Ports
AEM_AUTHOR_PORT=4502
AEM_PUBLISH_PORT=4503
DISPATCHER_PORT=8080

# (Optional) Path to client's dispatcher config
# If not set, SDK defaults are used
# DISPATCHER_PATH=/path/to/your-project/dispatcher/src
```

### Step 4: Start the environment

```bash
docker compose up -d
```

First startup takes 5-10 minutes for AEM to fully initialize. Monitor progress:

```bash
docker compose logs -f author
docker compose logs -f publish
```

### Step 5: Access the services

| Service | URL | Credentials |
|---------|-----|-------------|
| Author | http://localhost:4502 | admin / admin |
| Publish | http://localhost:4503 | admin / admin |
| Dispatcher | http://localhost:8080 | - |

## Virtual Hosts (vhosts) Setup

This section explains how to add custom domains to the dispatcher. An example `dummy.vhost` is included.

### How vhosts work

```
conf.d/
├── available_vhosts/          # All vhost definitions live here
│   ├── default.vhost          # SDK default (catch-all "*")
│   └── dummy.vhost            # Example: dummy.com project
└── enabled_vhosts/            # Symlinks to active vhosts
    ├── default.vhost -> ../available_vhosts/default.vhost
    └── dummy.vhost   -> ../available_vhosts/dummy.vhost
```

Only vhosts symlinked in `enabled_vhosts/` are loaded by Apache. This lets you have multiple vhost files and enable/disable them per environment.

### Example: dummy.com

The included `dummy.vhost` defines three VirtualHosts in a single file:

| ServerName | X-Vhost header | Purpose |
|------------|----------------|---------|
| `publish-dev.dummy.com` | `dummy-dev` | Local dev environment |
| `publish-stage.dummy.com` | `dummy-stage` | Staging environment |
| `dummy.com` / `www.dummy.com` | `dummy-prod` | Production (redirects www to non-www) |

### Step 1: Add domains to /etc/hosts

Since these are fake domains, point them to localhost:

```bash
sudo sh -c 'echo "127.0.0.1 dummy.com www.dummy.com publish-dev.dummy.com publish-stage.dummy.com" >> /etc/hosts'
```

Verify:
```bash
ping -c 1 publish-dev.dummy.com
# Should resolve to 127.0.0.1
```

### Step 2: Enable the vhost

```bash
cd dispatcher/dispatcher-sdk-2.0.235/src/conf.d/enabled_vhosts
ln -s ../available_vhosts/dummy.vhost dummy.vhost
```

### Step 3: Restart the dispatcher

```bash
docker compose up -d --force-recreate dispatcher
```

### Step 4: Test

```bash
# Should hit the dummy-dev vhost (check X-Vhost header)
curl -I http://publish-dev.dummy.com:8080/content/dummy/en.html

# Should hit the dummy-prod vhost
curl -I http://dummy.com:8080/content/dummy/en.html
```

### Creating your own vhost

1. Copy the example:
   ```bash
   cd dispatcher/dispatcher-sdk-2.0.235/src/conf.d/available_vhosts
   cp dummy.vhost myclient.vhost
   ```

2. Edit `myclient.vhost`:
   - Change `ServerName` to your client's domain
   - Change `X-Vhost` header values for debugging
   - Change the RewriteRule root path (`/content/dummy/en.html`) to your client's content root (e.g., `/content/myclient/en.html`)

3. Enable it:
   ```bash
   cd ../enabled_vhosts
   ln -s ../available_vhosts/myclient.vhost myclient.vhost
   ```

4. Add domains to `conf.dispatcher.d/virtualhosts/virtualhosts.any`:
   ```
   "myclient.com"
   "publish-dev.myclient.com"
   ```

5. Add domains to `/etc/hosts` and restart dispatcher.

### Disabling a vhost

```bash
# Just remove the symlink (not the file)
rm dispatcher/dispatcher-sdk-2.0.235/src/conf.d/enabled_vhosts/dummy.vhost
docker compose up -d --force-recreate dispatcher
```

## Using a Client's Dispatcher Configuration

By default, the dispatcher uses the SDK's default configuration. To use a client project's dispatcher config:

1. Set `DISPATCHER_PATH` in `.env` to the **absolute path** of the client's `dispatcher/src` directory:

   ```env
   DISPATCHER_PATH=/Users/yourname/Projects/client-project/dispatcher/src
   ```

   The directory should have this structure:
   ```
   dispatcher/src/
   ├── conf.d/
   │   ├── available_vhosts/    # Virtual host definitions
   │   ├── enabled_vhosts/      # Symlinks to active vhosts
   │   ├── rewrites/            # Rewrite rules
   │   └── variables/           # custom.vars, global.vars
   └── conf.dispatcher.d/
       ├── available_farms/     # Farm definitions
       ├── enabled_farms/       # Symlinks to active farms
       ├── cache/               # Cache rules
       ├── clientheaders/       # Headers passed to AEM
       ├── filters/             # Request filter rules
       ├── renders/             # Backend render definitions
       └── virtualhosts/        # Virtual host patterns
   ```

2. Recreate the dispatcher container:

   ```bash
   docker compose up -d --force-recreate dispatcher
   ```

To switch back to SDK defaults, simply comment out or remove `DISPATCHER_PATH` from `.env`.

## Replication Agent Setup

When configuring replication agents in AEM Author, use **Docker container names** instead of `localhost`:

- **Transport URI**: `http://publish:4503/bin/receive?sling:authRequestLogin=1`
- **User**: admin
- **Password**: admin

> `localhost` inside a container refers to itself, not the host machine. Use the container name `publish` which Docker resolves to the correct internal IP.

## JVM Memory Settings

Each AEM instance runs with the following JVM settings:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `-Xmx` | 4096m | Max heap size |
| `MaxMetaspaceSize` | 1024m | Max metaspace (OSGi class loading) |

Both instances together use ~11 GB. Make sure Docker Desktop has **at least 14-16 GB** of memory allocated (Settings -> Resources -> Memory).

> After `mvn clean install -PautoInstallPackage`, AEM restarts OSGi bundles, recompiles HTL/JSP, and rebuilds Oak indexes. This takes ~1-2 minutes even on fast machines. More heap and metaspace shortens this, but won't eliminate it completely.

## Remote Debugging

Both AEM instances have JDWP debugging enabled:

| Instance | Debug Port | IntelliJ Config |
|----------|------------|-----------------|
| Author | 30303 | Remote JVM Debug, host=localhost, port=30303 |
| Publish | 30304 | Remote JVM Debug, host=localhost, port=30304 |

## Common Operations

### Deploy code to Author
```bash
cd /path/to/aem-project
mvn clean install -PautoInstallPackage
```

> AEM takes ~2 minutes to restart OSGi bundles after package installation. This is normal.

### Deploy code to Publish
```bash
mvn clean install -PautoInstallPackage -Daem.port=4503
```

### View logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f dispatcher
docker compose logs -f author
docker compose logs -f publish
```

### Restart a single service
```bash
docker compose restart dispatcher
```

### Rebuild after Dockerfile changes
```bash
docker compose up -d --build author publish
```

### Reset a single service (e.g. publish only)
```bash
# Stop the service
docker compose stop publish

# Remove only its volume (author data stays intact)
docker volume rm ${COMPOSE_PROJECT_NAME}_publish_data

# Start fresh (uses pre-unpacked image, much faster than first time)
docker compose up -d publish
```

### Reset everything (destroys ALL AEM data)
```bash
docker compose down -v
docker compose up -d
```

> **Warning**: `docker compose down -v` removes **all** volumes (author, publish, dispatcher cache).
> If you only need to reset one instance, use the single service reset above.

## File Structure

```
aem-docker/
├── docker-compose.yml                  # Service orchestration
├── .env                                # Port and path configuration
├── author/
│   └── Dockerfile                      # Author instance (Temurin 21 + AEM JAR)
├── publish/
│   └── Dockerfile                      # Publish instance (Temurin 21 + AEM JAR)
├── dispatcher/
│   ├── Dockerfile                      # (Legacy, no longer used)
│   ├── aem-sdk-dispatcher-tools-*.sh   # SDK installer (for updates)
│   └── dispatcher-sdk-2.0.235/         # Extracted SDK
│       ├── bin/docker_run.sh           # SDK's standalone run script
│       ├── lib/                        # Pre-built Docker images + scripts
│       │   ├── dispatcher-publish-arm64.tar.gz
│       │   ├── dispatcher-publish-amd64.tar.gz
│       │   ├── import_sdk_config.sh
│       │   └── ...
│       └── src/                        # Default dispatcher configs
│           ├── conf.d/
│           └── conf.dispatcher.d/
└── install/                            # Licensed files (git-ignored)
    ├── aem-quickstart.jar
    └── cif-*.far
```

## Updating the Dispatcher SDK

1. Download the new `aem-sdk-dispatcher-tools-*-unix.sh` from Adobe Software Distribution
2. Place it in `dispatcher/` and extract:
   ```bash
   cd dispatcher
   chmod +x aem-sdk-dispatcher-tools-<version>-unix.sh
   ./aem-sdk-dispatcher-tools-<version>-unix.sh
   ```
3. Load the new Docker image:
   ```bash
   gunzip -c dispatcher-sdk-<version>/lib/dispatcher-publish-arm64.tar.gz | docker load
   ```
4. Update the image version in `docker-compose.yml`
5. Recreate the container:
   ```bash
   docker compose up -d --force-recreate dispatcher
   ```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Port already in use | Change ports in `.env` |
| AEM won't start | Ensure Docker has 8GB+ memory allocated |
| Dispatcher returns 503 | Publish isn't ready yet, wait for it to fully start |
| Dispatcher returns 403 | Check dispatcher filters in your config |
| Dispatcher not loading config | Verify `DISPATCHER_PATH` points to the `src/` directory |
| "Image not found" on dispatcher | Run the `docker load` command from Step 2 |
| Changes not visible after deploy | Wait ~2 min for bundles to restart, or flush dispatcher cache |

## License

This repository contains only configuration files. Licensed Adobe software (AEM JAR, CIF packages) must be obtained separately from Adobe Software Distribution and placed in the `install/` directory.
