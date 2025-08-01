# OpenFactory-AssetAPI — Serving Layer for Asset Data

[![Dev Container Ready](https://img.shields.io/badge/devcontainer-ready-green?logo=visualstudiocode\&labelColor=2c2c2c)](docs/devcontainer.md) <img src="https://img.shields.io/badge/python-3.12-blue?logo=python&logoColor=white" alt="Python Version" />
![License](https://img.shields.io/github/license/openfactoryio/openfactory-asset-api?style=flat-square) <img src="https://img.shields.io/badge/release-pre--release-yellow" alt="Pre-Release" />

---

**OpenFactory-AssetAPI** is the core serving layer within the [OpenFactory](https://github.com/Demo-Smart-Factory-Concordia-University/OpenFactory) platform. It provides efficient access to **real-time** and **computed asset data** through:

* 🔎 **State query endpoints**
* 📡 **Streaming interfaces**

Its modular, plugin-based architecture supports flexible deployment and grouping strategies, tailored to various industrial environments.

---

## 🚀 Quick Start

> This guide assumes deployment on an OpenFactory **Swarm** cluster.

### ✅ Prerequisites

* Python 3.12+
* Docker
* A running OpenFactory Swarm cluster
* (Optional) `jq` for pretty-printing JSON responses

---

### 🔧 1. Configure Environment

Create a `.env` file or export the following variables:

```env
GROUPING_STRATEGY=workcenter
DEPLOYMENT_PLATFORM=swarm
KSQLDB_URL=http://<ksqldb-ip>:8088
KAFKA_BROKER=<kafka-broker-ip>:9092
```

---

### ▶️ 2. Run

Install the package on a Swarm **manager node** of your OpenFactory cluster:

```bash
pip install -e .
```

Deploy the services:

```bash
manage deploy
```

---

### 🌐 3. Interact with the API

Query asset state:

```bash
curl "http://<OpenFactory-Cluster-IP>:5555/asset_state?asset_uuid=PROVER3018" | jq
```

Get specific asset data:

```bash
curl "http://<OpenFactory-Cluster-IP>:5555/asset_state?asset_uuid=PROVER3018&id=avail" | jq
```

Stream real-time telemetry:

```bash
curl "http://<OpenFactory-Cluster-IP>:5555/asset_stream?asset_uuid=PROVER3018"
```

---

## 🧩 Plugin System

The routing layer loads **grouping strategies** and **deployment platforms** dynamically using Python [entry points](https://packaging.python.org/en/latest/specifications/entry-points/) defined in `pyproject.toml`.

This enables:

* 🕹️ Runtime plugin selection via environment variables:

  * `GROUPING_STRATEGY`
  * `DEPLOYMENT_PLATFORM`
* ➕ Easy plugin extension without modifying core code

**Default plugins:**

* Grouping: `workcenter`
* Deployment: `swarm`, `docker`

<details>
<summary>ℹ️ <strong>Docker Deployment Info</strong></summary>

When using the <code>docker</code> deployment platform, start the local server manually with:

```bash
manage runserver
```

</details>

---

## 🛠 Development

### 🧪 Install for Dev

Install in editable mode with dev tools:

```bash
pip install -e .[dev]
./dev-setup.sh  # installs latest openfactory-core
```

---

### 💻 CLI Commands

Use the `manage` command for development tasks:

```bash
manage deploy       # deploys services and streams
manage runserver    # starts local API server
manage teardown     # cleans up services
```

> 💡 `manage` requires the package to be installed in editable mode.

---

### ✅ Code Quality

Run linting checks with:

```bash
flake8 .
```

---

## ⚙️ Configuration

Key environment variables:

| Variable              | Description                    | Default      |
| --------------------- | ------------------------------ | ------------ |
| `GROUPING_STRATEGY`   | Grouping plugin to load        | `workcenter` |
| `DEPLOYMENT_PLATFORM` | Deployment plugin to load      | `swarm`      |
| `KSQLDB_URL`          | ksqlDB endpoint URL            | *(None)*     |
| `KAFKA_BROKER`        | Kafka bootstrap server address | *(None)*     |

📚 For full configuration details, refer to:

* [`routing_layer/app/config.py`](routing_layer/app/config.py)
* [Routing Layer README](routing_layer/README.md#️-environment-configuration)

