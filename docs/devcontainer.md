# 🐳 Development Container Setup (VS Code + Dev Containers)

This project supports **Visual Studio Code Remote Containers**, using a pre-configured [Dev Container](https://containers.dev/) that:

✅ Automatically installs Python 3.12 and dev tools  
✅ Sets up the required environment variables  
✅ Installs and exposes the `openfactory-sdk` for managing local Kafka/ksqlDB instances  
✅ Provides a [Virtual Factory](#4-start-the-virtual-factory) to generate data to feed the OpenFactory-AssetAPI  
✅ Enables you to use `manage deploy`, `manage runserver`, and `manage teardown` without manual setup

---

## 🚀 Getting Started

### 1. Prerequisites

- [Docker](https://www.docker.com/)
- [VS Code](https://code.visualstudio.com/)
- [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

---

### 2. Open in Dev Container

1. Open this repository in VS Code  
2. Press `F1`, then select:

```
Dev Containers: Reopen in Container
````
VS Code will build the container using [.devcontainer/devcontainer.json](../.devcontainer/devcontainer.json).

---

### 3. Start Kafka + ksqlDB (One-node Dev Stack)

> ⚠️ **Note:** Kafka and ksqlDB are *not started automatically*.  
> You must run `spinup` before using any API management commands from the `manage` facility.

```bash
spinup
````

This will:

* Launch a single-node Kafka broker and ksqlDB instance (using the `openfactory-sdk` devcontainer feature)
* Export the required environment variables into your shell session

To stop and clean up:
```bash
teardown
```

---

### 4. Start the Virtual Factory

Before using the AssetAPI, deploy the virtual factory, which simulates asset devices producing telemetry. Without this, the API has no data to serve.

To deploy the virtual factory:
```bash
./dev_tools/deploy_virtual_factory.sh
```

This will:

* Start the virtual sensor
* Register virtual devices with the OpenFactory backend

You can use `ofa` commands to inspect and manage the virtual factory:
```bash
ofa asset ls                              # List deployed assets
ofa asset inspect VIRTUAL-TEMP-SENS-002   # Inspect a specific asset
```

To stop the virtual factory:
```bash
./dev_tools/teardown_virtual_factory.sh
```

---

> ⚠️ **Kafka Warnings Are Normal**
>
> When using `ofa`, you may see warnings like:
>
> ```text
> %3|1753376340.630|FAIL|rdkafka#producer-1| [thrd:broker:29092/bootstrap]: broker:29092/bootstrap: Failed to resolve 'broker:29092': No address associated with hostname (after 1ms in state CONNECT)
> ```
>
> These are expected — Kafka is attempting to connect to internal broker hostnames that are not resolvable from the dev container.
> It will automatically retry and reconnect using the proper advertised addresses once the cluster is ready.

---

### 5. Run the AssetAPI Application

First, the Docker images required by the AssetAPI must be built:
```bash
manage build
```
> **Note:** Re-run this command whenever you modify the source code of any component during development.

Once the infrastructure and virtual devices are running and the images are built,
you can manage the AssetAPI with the following commands:

```bash
manage deploy       # Set up ksqlDB streams and topics
manage runserver    # Start the FastAPI service
manage teardown     # Clean up application resources
```

To change the logging level, set the `LOG_LEVEL` environment variable:
```bash
LOG_LEVEL=debug manage runserver
```

To deploy the AssetAPI in a container, use
```bash
ENVIRONMENT=dev manage deploy    # Set up ksqlDB streams and topics and deploys the AssetAPI
ENVIRONMENT=dev manage teardown  # Clean up application resources
```

After the AssetAPI is running, you can stream data from the deployed devices on OpenFactory using:
```bash
curl localhost:5555/asset_stream?asset_uuid=VIRTUAL-TEMP-SENS-001
```
Or obtain it's state:
```bash
curl localhost:5555/asset_state?asset_uuid=VIRTUAL-TEMP-SENS-001 | jq
```

---

## 🧪 Available Features

| Feature                   | Description                          |
| ------------------------- | ------------------------------------ |
| Python 3.12               | Pre-installed in the container       |
| `ofa`                     | CLI tool for Asset management        |
| Kafka + ksqlDB (via SDK)  | One-node development setup           |
| VS Code Extensions        | Python + Docker tooling              |
| Dev Environment Variables | Set via `containerEnv` in the config |

---

## 🗂 File Reference

The dev container configuration lives in:

```bash
.devcontainer/devcontainer.json
```
You can customize this to add more packages, extensions, or tools as needed.

---

## 📌 Notes

* This is a **development-only environment** — not intended for production use.
* The `openfactory-sdk` version is pinned in the container config under `features` in [devcontainer.json](../.devcontainer/devcontainer.json) — update as needed.

---

## 🛠 Troubleshooting

* **Volume permission issues on Linux**: Ensure Docker is configured with the correct user permissions. You may need to add your user to the `docker` group or adjust file system permissions.
* **Container doesn't start?** Make sure Docker Desktop is running and that WSL 2 is enabled (for Windows users).
* **Virtual factory doesn't deploy?** After running `spinup` to start Kafka and ksqlDB, wait a few minutes to allow all streams and tables to initialize before proceeding.
