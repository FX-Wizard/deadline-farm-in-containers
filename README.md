# Deadline 10 Render Farm in Containers

*Docker service for building test render farms*
**Not for production use!**


## Setup

### 1. Get Installers

1. Download the installers from AWS
2. Extract the Deadline installer files into the `installers` folder


### 2. Build and Start All Services

```bash
docker compose build
```

On first start, the `deadline_repository` container will automatically run the Deadline Repository installer and connect to the MongoDB container. Subsequent starts will skip the installation since the repository is persisted in a named Docker volume.

> **Note:** The repository installation happens at runtime (not build time) because the installer needs a live MongoDB connection to complete.

To scale the number of worker containers, edit the `replicas` value in `docker-compose.yml`:

```yaml
deadline_worker:
  deploy:
    replicas: 3  # change this number
```

Or scale at runtime (without rebuilding):

```bash
docker compose up --scale deadline_worker=5
```

---

## Building Images Individually

### Build Repository Image

```bash
docker build -t deadline-repository:10.4.2.3 -f Dockerfile.repository .
```

### Build RCS Image

```bash
docker build -t deadline-rcs:10.4.2.3 -f Dockerfile.rcs .
```

### Build Worker Image

```bash
docker build -t deadline-worker:10.4.2.3 -f Dockerfile.worker .
```
