# 🐳 Day-01: Docker vs Virtual Machine

## 🔹 What is Docker?
<img width="1024" height="1024" alt="What is Docker" src="https://github.com/user-attachments/assets/c1d9b947-bf12-4b30-9df6-df3491dc01a8" />

Before understanding **Docker**, let’s look at the **traditional way of deploying applications** and the **challenges** we faced.

---

### 🧩 Traditional Deployment Challenges
<img width="1024" height="1024" alt="Traditional Deployment" src="https://github.com/user-attachments/assets/c1d9b947-bf12-4b30-9df6-df3491dc01a8" />

Let’s say you have **three environments** — **Development**, **Testing**, and **Production**.  
A developer writes some code and pushes it to a **version control system** like GitHub. The code is built and deployed into the **Dev environment**, and everything works fine.

---

### 🧑‍💻 “It works on my machine!”
<img width="1024" height="1024" alt="It Works on My Machine" src="https://github.com/user-attachments/assets/c1d9b947-bf12-4b30-9df6-df3491dc01a8" />

The developer says: “It works on my machine.”  
The **Operations** team says: “It’s an infrastructure issue.”

---

## 🚀 Why Containers?
<img width="1024" height="1024" alt="Why Containers" src="https://github.com/user-attachments/assets/c1d9b947-bf12-4b30-9df6-df3491dc01a8" />

With **containers**, we now **package everything** — application code, library versions, dependencies, and even the operating system image.  
✅ Developers are happy.  
✅ Ops teams are happy.  
✅ Everyone is happy.

---

## 🧱 What Exactly Is a Container?
<img width="1024" height="1024" alt="What Exactly Is a Container" src="https://github.com/user-attachments/assets/c1d9b947-bf12-4b30-9df6-df3491dc01a8" />

A **container** bundles:
- All **dependencies**
- All **libraries**
- The **application code**

Goal:
> **Build → Ship → Run**

---

## 🐋 Docker vs Container
<img width="1024" height="1024" alt="Docker vs Container" src="https://github.com/user-attachments/assets/c1d9b947-bf12-4b30-9df6-df3491dc01a8" />

**Docker** is a **platform** that helps you **build, ship, and run containers**.

---

## 🏠 Containers vs Virtual Machines (VMs)
<img width="1024" height="1024" alt="Container vs VM" src="https://github.com/user-attachments/assets/c1d9b947-bf12-4b30-9df6-df3491dc01a8" />

| Feature | Virtual Machine | Container |
|----------|----------------|------------|
| Isolation | Runs full OS | Shares host OS kernel |
| Resources | Heavy | Lightweight |
| Speed | Slower startup | Fast startup |
| Efficiency | Resource waste | Optimized usage |

---

## ⚙️ How VMs Work
<img width="1024" height="1024" alt="How VMs Work" src="https://github.com/user-attachments/assets/c1d9b947-bf12-4b30-9df6-df3491dc01a8" />

---

## ⚡ How Containers Work
<img width="1024" height="1024" alt="How Containers Work" src="https://github.com/user-attachments/assets/c1d9b947-bf12-4b30-9df6-df3491dc01a8" />

---

## 🧩 Docker Workflow
<img width="1024" height="1024" alt="Docker Workflow" src="https://github.com/user-attachments/assets/c1d9b947-bf12-4b30-9df6-df3491dc01a8" />

### Commands Example

```bash
docker build -t myapp:latest .
docker push myapp:latest
docker pull myapp:latest
docker run -d -p 8080:8080 myapp:latest
