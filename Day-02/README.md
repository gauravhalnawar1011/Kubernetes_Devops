-----

## Day 2: Hands-On Demo - Dockerizing a Simple Application 🐳

Welcome to Day 2\! Today, we'll get our hands dirty by taking a simple application and "Dockerizing" it. This means we'll create a Docker image for it, which is a portable package containing our application, its dependencies, and the necessary runtime.

### Prerequisites

Before we begin, you need a Docker environment. You have two options:

1.  **Local Installation (Recommended):** Ensure **Docker Desktop** is installed and running on your system.
2.  **Online Environment:** If you can't install Docker, you can use **Play with Docker**. It's a free, browser-based Docker playground.
      * Go to: [https://labs.play-with-docker.com/](https://labs.play-with-docker.com/)
      * Log in with your Docker Hub credentials. If you don't have an account, you'll need to sign up first.
      * Click "+ ADD NEW INSTANCE" to start a virtual session.

-----

### Step 1: Clone the Application Repository

First, let's get the source code for the sample application we'll be working with. Open your terminal and run the following command:

```bash
git clone https://github.com/docker/getting-started-app.git
```

This will download the application code into a new directory called `getting-started-app`.

-----

### Step 2: Understanding the `Dockerfile`

A **`Dockerfile`** is a text file that contains a set of instructions on how to build a Docker image. It's like a recipe for creating your container. Each instruction creates a new "layer" in the image.

Let's create a file named `Dockerfile` (no extension) inside the cloned repository and add the following content:

```dockerfile
# 1. Start with a base image
# We need a lightweight Linux OS with Node.js pre-installed.
# The 'alpine' tag means it's a minimal, lightweight version.
FROM node:18-alpine

# 2. Set the working directory inside the container
# All subsequent commands will run from this path.
WORKDIR /app

# 3. Copy application files from your machine to the container
# The first '.' is the source (current directory) and the second '.' is the destination (/app).
COPY . .

# 4. Install application dependencies
# This runs 'yarn install' inside the container to fetch the required packages.
RUN yarn install --production

# 5. Expose the port the application runs on
# This informs Docker that the container listens on port 3000.
EXPOSE 3000

# 6. Define the command to run when the container starts
# This will execute 'node src/index.js' to launch the app.
CMD ["node", "src/index.js"]
```

**Why Layers?** Docker builds images in layers. Each instruction in the `Dockerfile` adds a new layer. This makes builds, pushes, and pulls more efficient because Docker only needs to update the layers that have changed, rather than the entire image.

-----

### Step 3: Build the Docker Image

Now that we have our `Dockerfile`, let's build the image. Navigate to the `getting-started-app` directory in your terminal and run the `docker build` command.

  * The `-t` flag allows us to "tag" our image with a user-friendly name.
  * The `.` at the end tells Docker to look for the `Dockerfile` in the current directory.

<!-- end list -->

```bash
docker build -t getting-started-app .
```

After the build completes, you can see your new image by running:

```bash
docker images
```

-----

### Step 4: Push the Image to Docker Hub

To share your image or use it on another machine, you can push it to a registry like Docker Hub.

**1. Log in to Docker Hub**
Run the login command. You'll be prompted for your username and password.

```bash
docker login
```

> **Pro Tip:** For automated systems (CI/CD), it's better to use an access token:
> `echo "YOUR_ACCESS_TOKEN" | docker login --username YOUR_USERNAME --password-stdin`

**2. Tag the Image**
You need to re-tag your image to include your Docker Hub username. This tells Docker where to push it.

```bash
# Replace 'YOUR_USERNAME' with your actual Docker Hub username
docker tag getting-started-app YOUR_USERNAME/getting-started-app
```

**3. Push the Image**
Now, push the tagged image to Docker Hub.

```bash
# Replace 'YOUR_USERNAME' with your actual Docker Hub username
docker push YOUR_USERNAME/getting-started-app
```

You might notice that the image is compressed during the push, making the upload faster\!

-----

### Step 5: Run and Troubleshoot the Container

**Run the Container**
Let's run our newly created image\! The following command will start a container from your image.

```bash
# The -p flag maps port 3000 on your machine to port 3000 in the container
docker run -dp 3000:3000 YOUR_USERNAME/getting-started-app
```

You should now be able to access the application at `http://localhost:3000`.

**Troubleshoot Inside the Container**
If you need to debug or inspect a running container, you can get a shell session inside it using `docker exec`.

```bash
# First, get the container ID by running 'docker ps'
# Then, run the exec command:
docker exec -it <container-id-or-name> sh
```

Once inside, you'll be in the `/app` directory (as defined by `WORKDIR`). If you run `ls`, you'll see all the application files, including the `node_modules` folder.

> **Note on Best Practices:** Copying everything with `COPY . .` is simple, but it's not ideal because it also copies development files and local dependencies like `node_modules`. In a real-world scenario, you would use a `.dockerignore` file to exclude such directories.


## 🧩 1. `ENTRYPOINT` vs `CMD`

| Feature | `ENTRYPOINT` | `CMD` |
|----------|---------------|-------|
| **Purpose** | Defines the **main executable** that always runs | Defines **default arguments or fallback command** |
| **Overridable?** | Only with `--entrypoint` flag | Yes, via command in `docker run` |
| **Common Usage** | Set the *main program* or *startup script* | Set *default parameters* or *optional command* |
| **Can Work Together?** | ✅ Yes — `CMD` values are passed to `ENTRYPOINT` | — |
| **Format** | `ENTRYPOINT ["executable", "param1"]` | `CMD ["param2", "param3"]` |

### 🧠 Example
```dockerfile
FROM python:3.12
COPY app.py .
ENTRYPOINT ["python", "app.py"]
CMD ["World"]
````

#### Behavior:

| Command                                | What Happens               | Result           |
| -------------------------------------- | -------------------------- | ---------------- |
| `docker run myimage`                   | Runs `python app.py World` | → Hello, World!  |
| `docker run myimage Alice`             | Runs `python app.py Alice` | → Hello, Alice!  |
| `docker run --entrypoint bash myimage` | Overrides entrypoint       | Opens bash shell |

✅ **Best Practice:** Use both — `ENTRYPOINT` for command, `CMD` for defaults.

---

## 📁 2. `COPY` vs `ADD`

| Feature            | `COPY`                                      | `ADD`                                                       |
| ------------------ | ------------------------------------------- | ----------------------------------------------------------- |
| **Purpose**        | Copies files/directories from host to image | Copies files **and** supports extra features                |
| **Extra Features** | ❌ None                                      | ✅ Can extract `.tar` archives <br> ✅ Can download from URLs |
| **Best Practice**  | Use `COPY` for predictability               | Use `ADD` only if you need those extra features             |

**Example:**

```dockerfile
COPY app.py /app/
# vs
ADD app.tar.gz /app/   # Automatically extracts!
```

---

## 💬 3. `CMD` in Shell Form vs Exec Form

| Form           | Example                    | Behavior                              |
| -------------- | -------------------------- | ------------------------------------- |
| **Shell Form** | `CMD python app.py`        | Runs inside `/bin/sh -c` (uses shell) |
| **Exec Form**  | `CMD ["python", "app.py"]` | Runs directly (no shell, preferred)   |

✅ **Best Practice:** Always use **exec form** for signal handling & PID 1 reliability.

---

## 📂 4. `WORKDIR` vs `RUN cd`

| Feature         | `WORKDIR`                                             | `RUN cd`                                    |
| --------------- | ----------------------------------------------------- | ------------------------------------------- |
| **Purpose**     | Sets working directory for **all following commands** | Changes directory **only in current layer** |
| **Persistent?** | ✅ Yes                                                 | ❌ No                                        |

**Example:**

```dockerfile
WORKDIR /app
RUN ls     # Runs inside /app
```

✅ Use `WORKDIR`, not `RUN cd`.

---

## 🌐 5. `EXPOSE` vs `-p` (Publish Ports)

| Command                   | Description                                                       |
| ------------------------- | ----------------------------------------------------------------- |
| `EXPOSE 8080`             | Documents that the container listens on port 8080 (metadata only) |
| `docker run -p 8080:8080` | Actually maps container port to host port                         |

✅ `EXPOSE` = documentation only
✅ `-p` = actually exposes port to host

---

## 💾 6. `VOLUME` vs `Bind Mount`

| Type           | Definition                                 | Typical Use                                |
| -------------- | ------------------------------------------ | ------------------------------------------ |
| **Volume**     | Managed by Docker (`docker volume create`) | Persistent data (e.g., databases)          |
| **Bind Mount** | Maps a host folder directly                | Local development (e.g., live code reload) |

✅ **Volumes** → safe, portable, managed by Docker
✅ **Bind Mounts** → fast, good for local dev

---

## 🧱 7. Image Layers & Caching

* Each `RUN`, `COPY`, or `ADD` creates a new **layer**.
* Docker caches layers for faster builds.
* Changing one layer invalidates all layers *after* it.

**Example:**

```dockerfile
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
```

Changing app code won’t reinstall dependencies because of caching.

✅ **Best Practice:** Order layers from least to most frequently changing.

---

## ⚙️ 8. `RUN` vs `CMD` vs `ENTRYPOINT`

| Command        | When It Runs           | Purpose                       |
| -------------- | ---------------------- | ----------------------------- |
| **RUN**        | At **build time**      | Used to build the image       |
| **CMD**        | At **container start** | Provides default command/args |
| **ENTRYPOINT** | At **container start** | Defines main executable       |

✅ `RUN` = build phase
✅ `CMD` / `ENTRYPOINT` = runtime phase

---

## 🌱 9. `ENV` vs `.env` File

| Feature         | `ENV` in Dockerfile                         | `.env` File                                  |
| --------------- | ------------------------------------------- | -------------------------------------------- |
| **Usage**       | Sets environment variables **inside image** | Used with `docker run --env-file` or Compose |
| **Persistence** | Baked into image                            | External, configurable at runtime            |

✅ `ENV` = baked-in default
✅ `.env` = dynamic runtime configuration

---

## 🏗️ 10. Multi-Stage Builds

* Used to create **small, efficient** images.
* You build and then copy only what’s needed.

**Example:**

```dockerfile
# Stage 1: Build
FROM node:20 AS build
WORKDIR /app
COPY . .
RUN npm run build

# Stage 2: Runtime
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
```

✅ Reduces image size
✅ Keeps final image clean

---

## 🧠 Quick Recap

| Concept                  | Common Confusion            | Short Answer                                    |
| ------------------------ | --------------------------- | ----------------------------------------------- |
| ENTRYPOINT vs CMD        | Who runs / what changes     | ENTRYPOINT = main command, CMD = default args   |
| COPY vs ADD              | File copying                | Use COPY unless you need ADD’s tar/URL features |
| WORKDIR vs RUN cd        | Directory persistence       | WORKDIR persists, RUN cd doesn’t                |
| EXPOSE vs -p             | Port exposure vs publishing | EXPOSE = docs only, -p = real mapping           |
| RUN vs CMD vs ENTRYPOINT | When they run               | RUN = build time, CMD/ENTRYPOINT = runtime      |
| Volume vs Bind mount     | Data persistence            | Volume = managed, Bind = host path              |
| ENV vs .env              | Where variables live        | ENV = in image, .env = external                 |
| Shell vs Exec form       | CMD/ENTRYPOINT syntax       | Always use exec form                            |
| Layer caching            | Why rebuilds are slow       | Change order of layers                          |
| Multi-stage builds       | Image optimization          | Build → copy → shrink                           |

---

## 🏁 Final Notes

* 🧩 **ENTRYPOINT** = command
* ⚙️ **CMD** = arguments
* 🧱 **RUN** = build-time instruction
* 🚀 **WORKDIR**, **COPY**, **EXPOSE**, and **ENV** = supporting configuration

> 💡 **Tip:** Most Docker “gotchas” come from mixing *build-time* and *runtime* instructions — keep them separate and you’ll be fine.

## 🧩 11. `COPY` vs `ADD` vs `RUN curl/wget`

Sometimes people confuse `ADD` with `RUN curl` or `wget`.

| Method            | What It Does                                            | When to Use                                      |
| ----------------- | ------------------------------------------------------- | ------------------------------------------------ |
| **COPY**          | Copies local files                                      | When files are already in your build context     |
| **ADD**           | Same as COPY + supports remote URLs + extracts archives | Use *only* for TAR extraction                    |
| **RUN curl/wget** | Downloads files during build                            | When you need files from remote URLs dynamically |

✅ **Best Practice:**

* Use `COPY` → for local files
* Use `RUN curl -o` → for network downloads
* Avoid `ADD` for remote URLs — it hides behavior

---

## 🧱 12. `ARG` vs `ENV`

| Feature             | `ARG`                                     | `ENV`                              |
| ------------------- | ----------------------------------------- | ---------------------------------- |
| **Scope**           | Build-time variable                       | Runtime variable                   |
| **Available To**    | Only during `docker build`                | Inside the running container       |
| **Default Example** | `ARG VERSION=1.0`                         | `ENV VERSION=1.0`                  |
| **Access**          | `RUN echo $VERSION` (only while building) | `echo $VERSION` (inside container) |

✅ **Best Practice:**

* Use **ARG** for build configuration (like versions or proxies).
* Use **ENV** for runtime configuration.

---

## 🧠 13. `LABEL` vs `ENV`

| Feature      | `LABEL`                              | `ENV`                                     |
| ------------ | ------------------------------------ | ----------------------------------------- |
| **Purpose**  | Metadata about the image             | Environment variable inside the container |
| **Use Case** | Documentation, ownership, build info | Runtime config                            |
| **Example:** |                                      |                                           |

```dockerfile
LABEL maintainer="you@example.com"
ENV APP_ENV=production
```

✅ **LABEL** = metadata (doesn’t affect runtime).
✅ **ENV** = active runtime variable.

---

## 📦 14. Image Size Optimization Tips

| Tip                                        | Why It Matters                               |
| ------------------------------------------ | -------------------------------------------- |
| Use smaller base images (`alpine`, `slim`) | Reduces image size                           |
| Combine commands in one `RUN`              | Reduces layers                               |
| Clean up temp files                        | Saves space                                  |
| Use multi-stage builds                     | Keep final image minimal                     |
| Use `.dockerignore`                        | Prevents unnecessary files from being copied |

**Example:**

```dockerfile
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
```

✅ **One-liner = one layer** → smaller image.

---

## 🧹 15. `.dockerignore` File

Just like `.gitignore`, it excludes files from the build context.

**Example `.dockerignore`:**

```
node_modules
.git
*.log
.env
Dockerfile
README.md
```

✅ Prevents unnecessary files from being sent to Docker daemon → faster builds, smaller images.

---

## 🔁 16. `ONBUILD` Instruction (rare but interview-worthy)

| Feature      | Description                                                        |
| ------------ | ------------------------------------------------------------------ |
| **Purpose**  | Triggers a command **only when the image is used as a base image** |
| **Example:** |                                                                    |

```dockerfile
FROM node:20
ONBUILD COPY . /app
ONBUILD RUN npm install
```

| **Use Case** | Base images for other teams or templates |

✅ Triggers automatically when another Dockerfile uses `FROM your-image`.

---

## 🧩 17. Layer Caching & Invalidations (Advanced)

* Docker caches every instruction.
* Cache invalidates **if any input changes**.
* Even changing whitespace in a copied file can trigger rebuilds.

✅ **Optimize Build Order**

```dockerfile
# 1️⃣ Dependencies first (rarely change)
COPY requirements.txt .
RUN pip install -r requirements.txt

# 2️⃣ App code (changes frequently)
COPY . .
```

This ensures dependencies are cached between builds.

---

## 🧩 18. `HEALTHCHECK` Instruction

| Feature      | Description                        |
| ------------ | ---------------------------------- |
| **Purpose**  | Checks if the container is healthy |
| **Example:** |                                    |

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:8080/health || exit 1
```

| **Result** | Docker marks container as `healthy` or `unhealthy` |

✅ Use for production containers to monitor app health.

---

## 📋 19. `USER` Instruction

| Feature      | Description                           |
| ------------ | ------------------------------------- |
| **Purpose**  | Runs the container as a non-root user |
| **Example:** |                                       |

```dockerfile
RUN useradd -m appuser
USER appuser
```

| **Best Practice** | Always avoid running containers as `root` unless necessary |

✅ Enhances security by limiting permissions.

---

## 🔒 20. Security Best Practices

| Practice                          | Why                             |
| --------------------------------- | ------------------------------- |
| Use non-root users (`USER`)       | Prevent privilege escalation    |
| Pin versions (`FROM node:20.5.0`) | Ensures consistent builds       |
| Don’t store secrets in `ENV`      | Use secrets manager instead     |
| Scan images (`docker scan`)       | Detect vulnerabilities          |
| Use `.dockerignore`               | Avoid leaking credentials/files |

---

## 🏁 Final Recap — Complete Docker Confusion Killer 🧠

| Concept                  | Common Confusion          | Key Takeaway                     |
| ------------------------ | ------------------------- | -------------------------------- |
| ENTRYPOINT vs CMD        | Command vs arguments      | ENTRYPOINT = command, CMD = args |
| COPY vs ADD              | Copying vs downloading    | Use COPY, not ADD                |
| WORKDIR vs RUN cd        | Directory persistence     | WORKDIR persists                 |
| EXPOSE vs -p             | Docs vs actual publishing | -p exposes port                  |
| RUN vs CMD vs ENTRYPOINT | Build vs runtime          | RUN = build, others = run        |
| ARG vs ENV               | Build-time vs runtime     | ARG = build only                 |
| ENV vs .env              | Image vs external config  | ENV = baked in                   |
| LABEL vs ENV             | Metadata vs runtime       | LABEL = info only                |
| Volume vs Bind mount     | Managed vs host folder    | Volume = persistent              |
| Shell vs Exec form       | CMD syntax                | Use exec form                    |
| Multi-stage builds       | Optimization              | Build → copy → shrink            |
| HEALTHCHECK              | App monitoring            | Check container health           |
| USER                     | Security                  | Run as non-root                  |
| .dockerignore            | Build speed               | Exclude junk files               |
| ONBUILD                  | Template logic            | Trigger when used as base        |
| Layer caching            | Slow rebuilds             | Order instructions smartly       |

---

## 🧠 TL;DR

> * **ENTRYPOINT** → what always runs
> * **CMD** → default arguments
> * **RUN** → build-time commands
> * **ARG** → build-time variables
> * **ENV** → runtime variables
> * **COPY** → copy files
> * **WORKDIR** → set working directory
> * **EXPOSE** → document ports
> * **USER** → set permissions
> * **VOLUME** → manage data
> * **HEALTHCHECK** → monitor container health

---

**✅ Pro Tip:**
If you can confidently explain:

* `ENTRYPOINT vs CMD`
* `RUN vs CMD`
* `COPY vs ADD`
* `ARG vs ENV`
  …you’ll already be ahead of 90% of candidates in Docker interviews. 🚀

---

**Author:** Gaurav Halanwar *Docker/DevOps Cheat Sheet — made for interviews and clarity.*

**Purpose:** To remove all confusion around Docker fundamentals for interviews and real-world usage.

---


