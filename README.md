# AEM Docker Development Environment

This project provides a Docker-based development environment for Adobe Experience Manager (AEM) with Author, Publish, and Dispatcher services.

## Architecture

The setup includes:
- **AEM Author** instance (port 4502) with remote debugging on port 30303
- **AEM Publish** instance (port 4503) with remote debugging on port 30304  
- **Apache Dispatcher** (port 8080) configured for the publish instance
- **CIF (Commerce Integration Framework)** support

## Prerequisites

- Docker and Docker Compose installed
- AEM QuickStart JAR file
- CIF Feature Packages
- (Optional) WKND sample content packages

## Required Files (Git Ignored)

⚠️ **Important**: The following files are required but excluded from git for licensing reasons. You must obtain and place them manually:

### `/install/` directory

Place the following files in the `install/` directory:

1. **`aem-quickstart.jar`** - The main AEM QuickStart JAR file
   - Download from Adobe Software Distribution
   - This is the core AEM runtime

2. **CIF Feature Packages** (already configured):
   - `cif-cloud-ready-feature-pkg-2024.09.05.00-cq-commerce-addon-authorfar.far`
   - `cif-cloud-ready-feature-pkg-2024.09.05.00-cq-commerce-addon-publishfar.far`
   - Download from Adobe Software Distribution

3. **Optional Content Packages**:
   - `wknd-author-content.zip` (uncomment line in `author/Dockerfile` to use)
   - Any other custom content packages you want to install

### `/dispatcher/` directory

The dispatcher SDK tools are already included, but if you need to update:

1. **`aem-sdk-dispatcher-tools-*.sh`** - Dispatcher SDK installer script
   - Download latest version from Adobe Software Distribution
   - Current version: `aem-sdk-dispatcher-tools-2.0.235-unix.sh`

   ```bash
   cd dispatcher
   run chmod a+x aem-sdk-dispatcher-tools-2.0.235-unix.sh && ./aem-sdk-dispatcher-tools-2.0.235-unix.sh
   ```

## Setup Instructions

1. **Clone this repository**
   ```bash
   git clone <repository-url>
   cd aem-docker
   ```

2. **Place required files**
   - Copy `aem-quickstart.jar` to `install/` directory
   - Copy CIF feature packages to `install/` directory
   - (Optional) Copy any additional content packages to `install/` directory

3. **Configure environment** (optional)
   - Edit `.env` file to change ports or project name
   - Default ports: Author (4502), Publish (4503), Dispatcher (8080)

4. **Start the environment**
   ```bash
   docker-compose up -d
   ```

5. **Access the services**
   - AEM Author: http://localhost:4502
   - AEM Publish: http://localhost:4503  
   - Dispatcher: http://localhost:8080

## Development

### Remote Debugging

Both AEM instances are configured for remote debugging:
- Author: port 30303
- Publish: port 30304

### Dispatcher Configuration

Dispatcher configuration is located in `dispatcher/dispatcher-sdk-2.0.235/src/`:
- Virtual hosts: `conf.d/available_vhosts/`
- Farms: `conf.dispatcher.d/available_farms/`
- Rewrites: `conf.d/rewrites/`

### Data Persistence

AEM data is persisted in Docker volumes:
- `author_data`: Author instance data
- `publish_data`: Publish instance data  
- `dispatcher_cache`: Dispatcher cache

## File Structure

```
├── docker-compose.yml          # Main orchestration file
├── .env                        # Environment configuration
├── author/
│   └── Dockerfile             # Author instance configuration
├── publish/
│   └── Dockerfile             # Publish instance configuration
├── dispatcher/
│   ├── Dockerfile             # Dispatcher configuration
│   └── dispatcher-sdk-2.0.235/ # Dispatcher SDK and configuration
└── install/                   # Place AEM JAR and packages here (git ignored)
    ├── aem-quickstart.jar     # ⚠️ Required: Place manually
    ├── cif-*.far              # ⚠️ Required: Place manually
    └── *.zip                  # Optional: Additional content packages
```

## Troubleshooting

### Common Issues

1. **Port conflicts**: Change ports in `.env` file if default ports are in use
2. **Memory issues**: Ensure Docker has sufficient memory allocated (8GB+ recommended)
3. **AEM startup**: First startup can take 5-10 minutes for AEM to fully initialize

### Logs

View service logs:
```bash
docker-compose logs -f author
docker-compose logs -f publish  
docker-compose logs -f dispatcher
```

### Reset Environment

To completely reset the environment:
```bash
docker-compose down -v
docker-compose up -d
```

## License Notes

This repository contains only configuration files. You must separately obtain licensed Adobe software:
- AEM QuickStart JAR
- CIF Feature Packages
- Any other Adobe packages

These files are excluded from version control and must be placed manually in the appropriate directories.