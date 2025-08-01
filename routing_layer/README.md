# Routing Layer for OpenFactory's Serving Layer

## Overview
The Routing Layer’s mission is to dynamically route client requests for asset data to the appropriate group-specific service instances, ensuring efficient, scalable, and isolated data delivery tailored to logical groupings of assets.

The Routing Layer manages asset grouping, stream generation, and deployment of group-specific services to enable scalable, targeted data serving. It integrates tightly with ksqlDB, Kafka, and Docker Swarm to dynamically create and maintain streams and services based on asset metadata.

## On Startup

* 🔄 **Generate derived Kafka streams/topics using ksqlDB based on group metadata (e.g., `workcenter`)**

  * The layer queries the Unified Namespace (UNS) mapping table to discover all active groups.
  * For each group, it creates a dedicated Kafka stream filtered to only the assets in that group.
  * Derived streams are named consistently as `asset_stream_<Group>`, enabling predictable topic access.
  * Example query pattern (simplified):

    ```sql
    CREATE STREAM asset_stream_Weld AS
        SELECT s.*
        FROM ofa_assets s
        JOIN asset_to_uns_map h ON s.asset_uuid = h.asset_uuid
        WHERE h.uns_levels['workcenter'] = 'Weld';
    ```

* 🏗️ **Deploy FastAPI group services via Docker Swarm**

  * For each discovered group, the routing layer checks whether a Docker Swarm service named `ofa_group_<Group>` exists.
  * If the service is missing, it uses the Docker SDK to deploy a new service instance.
  * Each deployed service is configured via environment variables (e.g., `GROUP_NAME=Weld`) so it consumes its assigned Kafka stream.


* 🧾 **Maintain a local registry**

  * The routing layer keeps an internal mapping of groups to their service URLs, e.g., `http://ofa_group_Weld:8000/asset_stream`.

## At Runtime

* 🛰️ **Handle incoming client requests to `/asset_stream?asset_uuid=...`**

  * The routing layer queries the asset’s group membership by inspecting the UNS mapping, identifying the correct group (e.g., workcenter = `"Weld"`).
  * It checks whether the group’s service is deployed and accessible.
    * If missing, it can trigger lazy deployment to launch the group service on demand.
  * The client request is proxied or redirected transparently to the group-specific service endpoint, such as `/group/Weld/asset_stream?...`.

## Additional Details

* **Grouping strategy**
  * The `UNSLevelGroupingStrategy` is used to assign assets to groups based on a configurable UNS level.
  * Group membership and group lists are dynamically queried from ksqlDB.

* **Stream management**
  * Derived streams filter the master asset stream using UNS attributes, ensuring data isolation per group.

* **Deployment abstraction**
  * The deployment platform interface supports multiple backends; currently, Docker Swarm is implemented.

* **Security**
  * All dynamic ksqlDB queries sanitize input values to prevent injection attacks.

* **Configuration**
  * Deployment settings, Kafka brokers, ksqlDB URLs, and Docker image names are managed centrally in the shared `settings` module.


## ⚙️ Environment Configuration

Configured via environment variables (typically via a shared `.env` file):

### 🔌 Kafka & ksqlDB

| Variable               | Description                                              | Required                                  |
| ---------------------- | -------------------------------------------------------- | ----------------------------------------- |
| `KAFKA_BROKER`         | Kafka bootstrap server address (e.g., `localhost:9092`)  | ✅ Yes                                    |
| `KSQLDB_URL`           | URL of the ksqlDB server (e.g., `http://localhost:8088`) | ✅ Yes                                    |
| `KSQLDB_ASSETS_STREAM` | Name of the ksqlDB stream with enriched asset data       | ❌ No (default: `enriched_assets_stream`) |
| `KSQLDB_ASSETS_TABLE`  | Name of the table containing assets states               | ❌ No (default: `assets`)                 |
| `KSQLDB_UNS_MAP`       | Name of the ksqlDB table mapping assets to UNS hierarchy | ❌ No (default: `asset_to_uns_map`)       |

### 🐳 Docker & Swarm

| Variable          | Description                                  | Required                       |
| ----------------- | -------------------------------------------- | ------------------------------ |
| `DOCKER_NETWORK`  | Docker Swarm overlay network name            | ❌ No (default: `factory-net`) |
| `SWARM_NODE_HOST` | Host or IP address of the Swarm manager node | ❌ No (default: `localhost`)   |

### 🚦 Routing Layer

| Variable                        | Description                                        | Required                             |
| ------------------------------- | -------------------------------------------------- | ------------------------------------ |
| `ROUTING_LAYER_IMAGE`           | Docker image for the central routing layer API     | ❌ No (default: `ghcr.io/.../routing-layer:latest`) |
| `ROUTING_LAYER_REPLICAS`        | Number of routing layer replicas                   | ❌ No (default: `1`)                 |
| `ROUTING_LAYER_CPU_LIMIT`       | CPU limit per routing layer container              | ❌ No (default: `1`)                 |
| `ROUTING_LAYER_CPU_RESERVATION` | CPU reservation per routing layer container        | ❌ No (default: `0.5`)               |
| `GROUPING_STRATEGY`             | Strategy used to group assets (e.g., `workcenter`) | ❌ No (default: `workcenter`)        |
| `DEPLOYMENT_PLATFORM`           | Deployment mode: `swarm` or `docker`               | ❌ No (default: `swarm`)             |

### 🧩 FastAPI Group Services

| Variable                           | Description                                                    | Required                                            |
| ---------------------------------- | -------------------------------------------------------------- | --------------------------------------------------- |
| `FASTAPI_GROUP_IMAGE`              | Docker image for group services                                | ❌ No (default: `ghcr.io/.../stream-api-non-replicated:latest`) |
| `FASTAPI_GROUP_REPLICAS`           | Number of group service replicas                               | ❌ No (default: `1`)                                |
| `FASTAPI_GROUP_CPU_LIMIT`          | CPU limit per group container                                  | ❌ No (default: `1`)                                |
| `FASTAPI_GROUP_CPU_RESERVATION`    | CPU reservation per group container                            | ❌ No (default: `0.5`)                              |
| `FASTAPI_GROUP_PORT_BASE`          | Base port for exposing group services during local development | ❌ No (default: `6000`)                             |
| `UNS_FASTAPI_GROUP_GROUPING_LEVEL` | Grouping level for UNS-based FastAPI services                  | ❌ No (default: `workcenter`)                       |

### 🔄 Asset State API

| Variable                    | Description                                     | Required                                        |
| --------------------------- | ----------------------------------------------- | ----------------------------------------------- |
| `STATE_API_IMAGE`           | Docker image for the asset state API service    | ❌ No (default: `ghcr.io/.../state-api:latest`) |
| `STATE_API_REPLICAS`        | Number of replicas for the state API            | ❌ No (default: `1`)                            |
| `STATE_API_CPU_LIMIT`       | CPU limit per container for the state API       | ❌ No (default: `0.5`)                          |
| `STATE_API_CPU_RESERVATION` | CPU reservation per container for the state API | ❌ No (default: `0.25`)                         |

### 🛠️ Miscellaneous

| Variable      | Description                                                     | Required                      |
| ------------- | --------------------------------------------------------------- | ----------------------------- |
| `ENVIRONMENT` | App environment (`local`, `devswarm`, or `production`)          | ❌ No (default: `production`) |
| `LOG_LEVEL`   | Logging level (`debug`, `info`, `warning`, `error`, `critical`) | ❌ No (default: `info`)       |

---

## 🐳 Running Locally

### 🐳 Run with Docker + Swarm

Build the Docker image:
```bash
docker build -t openfactory/routing-layer .
```

Then deploy the full routing layer infrastructure:
```bash
python -m routing_layer.manage deploy
```

> **Note:**
> If `ENVIRONMENT=local` is set, the `deploy` command will **skip deploying the routing layer API** to the Swarm cluster. This allows you to run the API locally while still deploying group services inside Swarm.

To tear down all deployed services:
```bash
python -m routing_layer.manage teardown
```

---

### ▶️ Run the Routing Layer API Locally

If you're using `ENVIRONMENT=local`, run the **FastAPI** app locally using Uvicorn:
```bash
python -m routing_layer.app.main
```
or
```bash
python -m routing_layer.manage runserver
```
This will start the API server at `http://localhost:5555` using the environment defined in your `.env`.

---

## 🔧 Development Structure

```bash
routing_layer/
├── app/
│   ├── api/
│   │   ├── router_asset.py                     # FastAPI route for asset streaming proxy
│   │   └── router_asset_state.py               # FastAPI route for asset state proxy
│   ├── config.py                               # Environment variable and ksqlDB config
│   ├── core/
│   │   ├── controller/
│   │   │   ├── deployment_platform.py          # Abstract base for deployment backends
│   │   │   ├── docker_deployment_platform.py   # Local Docker deployment logic
│   │   │   ├── swarm_deployment_platform.py    # Docker Swarm deployment logic
│   │   │   ├── grouping_strategy.py            # Base class for asset grouping
│   │   │   ├── unslevel_grouping_strategy.py   # UNS-level based grouping logic
│   │   │   ├── routing_controller.py           # Orchestrates grouping + deployment
│   │   │   └── __init__.py
│   │   ├── logger.py                           # Shared logging setup
│   │   ├── proxy.py                            # Local proxy routing helpers
│   │   ├── utils.py                            # Utility functions
│   │   └── __init__.py
│   ├── dependencies.py                         # Dependency injection for FastAPI
│   └── main.py                                 # App factory and FastAPI entrypoint
├── deployment/
│   ├── deploy.py                               # CLI entry for deploying group services
│   └── teardown.py                             # CLI entry to teardown services
├── docker-compose.yml                          # Docker Compose for local dev
├── Dockerfile                                  # Docker image definition
├── manage.py                                   # Unified CLI (runserver, deploy, teardown)
├── README.md                                   # This file
└── __init__.py
```
