
---

# 🐳 Day 28 — Docker Volumes

## 📘 Overview

In Docker, images are built in **layers**. When we rebuild an image, Docker uses a **layer cache** to speed up the process — unchanged layers are copied from the cache instead of being rebuilt.

Each layer in a Docker image is **read-only**, meaning you cannot modify it directly. If changes are required, a **new image build** is triggered, creating a new layer on top of the existing ones.

This concept forms the basis of **immutable infrastructure** — once an image is built and tested, it remains unchanged and can be safely promoted from one environment (e.g., dev → staging → prod).

---

## 🧱 Layers and the Writable Container Layer

When you run a container from an image, Docker creates a **writable layer** on top of the image’s read-only layers.
This writable layer is unique to the container — any data written inside the container is stored here.

However, this data **only persists for the container’s lifetime**. Once the container is removed, all data stored in the writable layer is lost.

---

## 💾 Making Data Persistent

To persist data beyond a container’s lifecycle, Docker provides **volumes** and **bind mounts**.

### 🔹 Docker Volumes

Volumes are managed by Docker and stored under:

```
/var/lib/docker/volumes/
```

Let’s create a new Docker volume:

```bash
sudo docker volume create data_volume
docker volume ls
```

You can verify where the volume data resides:

```bash
cd /var/lib/docker/volumes/data_volume/_data
```

This is where all persistent volume data is stored.

---

### 🔹 Using Volumes in Containers

You can attach a volume to a container using the `-v` flag:

```bash
docker run -v data_vol:/app \
  -dp 3000:3000 \
  --name=docker-with-volumes \
  day27
```

Now, let’s interact with the container:

```bash
docker exec -it docker-with-volumes sh
```

Inside the container:

```bash
/app # mkdir demo1
/app # echo "hello from the docker volumes" > docker.sh
/app # ls
README.md  demo1  docker.sh  node_modules  package.json  src  yarn.lock
/app # cat docker.sh
hello from the docker volumes
/app # exit
```

Now, even if you stop or remove the container and reattach the same volume, your data will still persist:

```bash
docker rm -f docker-with-volumes
docker run -v data_vol:/app \
  -dp 3000:3000 \
  --name=new-container-with-volumes \
  day27
```

The data inside `/app` will still be available because it’s stored in the `data_vol` volume.

---

## 🧩 Bind Mounts vs Volumes

| Feature     | Volumes                           | Bind Mounts                                |
| ----------- | --------------------------------- | ------------------------------------------ |
| Managed by  | Docker                            | User / Host                                |
| Location    | `/var/lib/docker/volumes/`        | Any path on host machine                   |
| Use Case    | Persisting data across containers | Sharing code/configs from local filesystem |
| Portability | High                              | Host-dependent                             |

Example of a **bind mount**:

```bash
docker run -v $(pwd):/app \
  -dp 3000:3000 \
  --name=docker-bind-mount \
  day27
```

Changes in your local directory will instantly reflect inside the container.

---

## ⚙️ Storage Drivers

Storage drivers are responsible for handling the image and container layers. Common drivers include:

* **overlay2** (default on Ubuntu, CentOS, Fedora)
* **aufs** and **device-mapper** (deprecated)

Docker automatically selects the best driver for your OS.

---

## ☁️ Volume Drivers

When storing persistent data, Docker uses **volume drivers**.
The default driver is `local` (stores data on the host).
Cloud-based storage can use drivers for:

* **EBS** / **EFS** (AWS)
* **Azure File Storage**
* **NFS** and others

These allow containers to share data across hosts and environments.

---

## 🧭 Summary

* Docker images are **immutable** and consist of **read-only layers**.
* Containers add a **writable layer** on top of these.
* To persist data beyond a container’s lifecycle, use **volumes**.
* **Storage drivers** manage how data is written in layers.
* **Volume drivers** handle persistent storage across containers and hosts.

---

## 🐋 Example Dockerfile

Here’s a simple example of a **professional Dockerfile** that you can use:

```dockerfile
# syntax=docker/dockerfile:1

# Use an official Node.js LTS image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install --production

# Copy the rest of the source code
COPY . .

# Expose the application port
EXPOSE 3000

# Run the application
CMD ["npm", "start"]
```

---

