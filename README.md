<div align="center">
  
# 🌐 AEM Docker Development Environment 
  [![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
  [![Adobe AEMaaCS](https://img.shields.io/badge/Adobe%20AEMaaCS-FF0000?style=for-the-badge&logo=adobe&logoColor=white)](https://business.adobe.com/products/experience-manager/adobe-experience-manager.html)
  [![Apache](https://img.shields.io/badge/Apache-D22128?style=for-the-badge&logo=apache&logoColor=white)](https://httpd.apache.org/)
</div>

This project provides a Docker-based development environment for Adobe Experience Manager (AEM) with Author, Publish, and Dispatcher services.

## 🏗️ Architecture

The setup includes:
- **🖥️ AEM Author** instance (port 4502) with remote debugging on port 30303
- **📰 AEM Publish** instance (port 4503) with remote debugging on port 30304  
- **🚦 Apache Dispatcher** (port 8080) configured for the publish instance
- **🛒 CIF (Commerce Integration Framework)** support

## 📋 Prerequisites

- 🐳 Docker and Docker Compose installed
- 📦 AEM QuickStart JAR file
- 🛍️ CIF Feature Packages
- 📚 (Optional) WKND sample content packages

## 📁 Required Files (Git Ignored)

⚠️ **Important**: The following files are required but excluded from git for licensing reasons. You must obtain and place them manually:

### 📦 `/install/` directory

Place the following files in the `install/` directory:

1. **📄 `aem-quickstart.jar`** - The main AEM QuickStart JAR file
   - 📥 Download from Adobe Software Distribution
   - This is the core AEM runtime

2. **🛍️ CIF Feature Packages** (already configured):
   - `cif-cloud-ready-feature-pkg-2024.09.05.00-cq-commerce-addon-authorfar.far`
   - `cif-cloud-ready-feature-pkg-2024.09.05.00-cq-commerce-addon-publishfar.far`
   - 📥 Download from Adobe Software Distribution

3. **📚 Optional Content Packages**:
   - `wknd-author-content.zip` (uncomment line in `author/Dockerfile` to use)
   - Any other custom content packages you want to install

### 🚦 `/dispatcher/` directory

The dispatcher SDK tools are already included, but if you need to update:

1. **🔧 `aem-sdk-dispatcher-tools-*.sh`** - Dispatcher SDK installer script
   - 📥 Download latest version from Adobe Software Distribution
   - Example version: `aem-sdk-dispatcher-tools-2.0.235-unix.sh`
   - Place it manually in `dispatcher/` directory
   - Run bash script to extract its content

   ```bash
   cd dispatcher
   chmod a+x aem-sdk-dispatcher-tools-x.y.z-unix.sh && ./aem-sdk-dispatcher-tools-x.y.z-unix.sh
   ```
   - Set `DISPATCHER_SDK_VERSION` in `.env` and run `./scripts/dispatcher.sh load` (see [Dispatcher Configuration](#️-dispatcher-configuration-any-aem-project))

## 🚀 Setup Instructions

1. **📥 Clone this repository**
   ```bash
   git clone <repository-url>
   cd aem-docker
   ```

2. **📁 Place required files**
   - Copy `aem-quickstart.jar` to `install/` directory
   - Copy CIF feature packages to `install/` directory
   - (Optional) Copy any additional content packages to `install/` directory

3. **⚙️ Configure environment** (optional)
   - Edit `.env` file to change ports or project name
   - Default ports: Author (4502, debug 30303), Publish (4503, debug 30304), Dispatcher (8080)

4. **🐳 Start the environment**
   
   > ⚠️ **Important**: Before running `docker-compose up -d`, take a look at README.md files in particular folders and follow their instructions.
   
   ```bash
   docker-compose up -d
   ```

5. **🌐 Access the services**
   - 🖥️ AEM Author: http://localhost:4502
   - 📰 AEM Publish: http://localhost:4503  
   - 🚦 Dispatcher: http://localhost:8080

## ⚙️ Docker Networking Notes

**Replication Agent Configuration:**
When configuring replication agents in AEM Author, use container names instead of localhost:

- ❌ **Don't use**: `http://localhost:4503/bin/receive?sling:authRequestLogin=1`
- ✅ **Use instead**: `http://publish:4503/bin/receive?sling:authRequestLogin=1`

**Why?** Docker containers communicate using container names as hostnames within the Docker network. The `publish` container name resolves to the correct internal IP address, while `localhost` refers to the container's own loopback interface, causing connection refused errors.

## 🛠️ Development

### 🐛 Remote Debugging

Both AEM instances are configured for remote debugging:
- 🖥️ Author: port 30303
- 📰 Publish: port 30304

### ⚙️ Dispatcher Configuration (any AEM project)

The dispatcher runs the official AEMaaCS image shipped with the Dispatcher SDK
(`adobe/aem-ethos/dispatcher-publish`), so it works with the `dispatcher/src`
config of **any** AEM project (generated from the AEM Project Archetype).
The project's config is mounted into the container, nothing is copied into this repo.

1. **Load the dispatcher image** (once per SDK version, after extracting the SDK into `dispatcher/`):
   ```bash
   ./scripts/dispatcher.sh load
   ```

2. **Point the dispatcher to your project**. You can pass the project root, its `dispatcher` folder or `dispatcher/src`:
   ```bash
   ./scripts/dispatcher.sh use ~/projects/wknd
   ```
   This sets `DISPATCHER_CONFIG_DIR` in `.env` and recreates the dispatcher container.
   You can also edit `DISPATCHER_CONFIG_DIR` in `.env` by hand. By default the SDK example config is used.

3. **Other commands**
   ```bash
   ./scripts/dispatcher.sh reload     # restart after changing config files
   ./scripts/dispatcher.sh validate   # run the SDK validator on the current config
   ./scripts/dispatcher.sh current    # show the config currently in use
   ```

Dispatcher settings in `.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `DISPATCHER_SDK_VERSION` | `2.0.235` | Version of the extracted SDK / image tag |
| `DISPATCHER_CONFIG_DIR` | SDK example `src` | Folder with `conf.d` and `conf.dispatcher.d` |
| `DISPATCHER_AEM_HOST` | `publish` | Backend host (`host.docker.internal` for AEM running on your machine) |
| `DISPATCHER_AEM_PORT` | `4503` | Backend port |
| `DISP_LOG_LEVEL` / `REWRITE_LOG_LEVEL` | `Warn` | Log levels (e.g. `Debug`, `Trace1`) |
| `COMMERCE_ENDPOINT` | `http://localhost/graphql` | GraphQL endpoint used by CIF configs |

Inside the project config:
- 🌐 Virtual hosts: `conf.d/available_vhosts/`
- 🚜 Farms: `conf.dispatcher.d/available_farms/`
- 🔄 Rewrites: `conf.d/rewrites/`

### 💾 Data Persistence

AEM data is persisted in Docker volumes:
- 📂 `author_data`: Author instance data
- 📂 `publish_data`: Publish instance data  
- 📂 `dispatcher_cache`: Dispatcher cache

## 📁 File Structure

```
├── 🐳 docker-compose.yml          # Main orchestration file
├── ⚙️ .env                        # Environment configuration
├── 🖥️ author/
│   └── Dockerfile             # Author instance configuration
├── 📰 publish/
│   └── Dockerfile             # Publish instance configuration
├── 🚦 dispatcher/
│   └── dispatcher-sdk-2.0.235/ # ⚠️ Required: Place manually (image + validator)
├── 🧰 scripts/
│   └── dispatcher.sh          # Load image, switch project config, validate, reload
└── 📦 install/                   # Place AEM JAR and packages here (git ignored)
    ├── aem-quickstart.jar     # ⚠️ Required: Place manually
    ├── cif-*.far              # ⚠️ Required: Place manually
    └── *.zip                  # Optional: Additional content packages
```

## 🔧 Troubleshooting

### ⚠️ Common Issues

1. **🚪 Port conflicts**: Change ports in `.env` file if default ports are in use
2. **💾 Memory issues**: Ensure Docker has sufficient memory allocated (8GB+ recommended)
3. **⏱️ AEM startup**: First startup can take 5-10 minutes for AEM to fully initialize

### 📋 Logs

View service logs:
```bash
docker-compose logs -f author
docker-compose logs -f publish  
docker-compose logs -f dispatcher
```

### 🔄 Reset Environment

To completely reset the environment:
```bash
docker-compose down -v
docker-compose up -d
```

## 📄 License Notes

This repository contains only configuration files. You must separately obtain licensed Adobe software:
- 📦 AEM QuickStart JAR
- 🛍️ CIF Feature Packages
- 📚 Any other Adobe packages

These files are excluded from version control and must be placed manually in the appropriate directories.