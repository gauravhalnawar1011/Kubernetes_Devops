
---

# Day-65: Integrating GitHub SSO Authentication with ArgoCD

### Configuring GitHub OAuth, ArgoCD SSO, and SSL with Certbot

This project demonstrates how to integrate **GitHub Single Sign-On (SSO)** with **ArgoCD**, along with securing the ArgoCD endpoint using **NGINX** and **Certbot SSL**.
ArgoCD natively supports third-party identity providers such as Okta, GitHub, and others. In this implementation, GitHub is used as the OAuth provider to streamline authentication, simplify access management, and improve security across DevOps workflows.

---

## Prerequisites

Before beginning, ensure the following components are available:

* AWS account with an **Ubuntu 24.04 LTS EC2 instance**
* **Minikube** and **kubectl** installed
* Basic understanding of **Kubernetes** and **GitHub**
* A registered **domain name** (e.g., GoDaddy)

---

## Step 1: Configure DNS for the Custom Domain

1. Log in to your GoDaddy account and navigate to **My Products**.
2. Create or update an **A Record**:

   * **Type:** A
   * **Name:** @
   * **Value:** Public Elastic IP of your EC2 instance
   * **TTL:** 1 Hour

This ensures your domain resolves to the EC2 instance hosting your NGINX proxy.

---

## Step 2: Install and Configure NGINX with Certbot SSL

### Install NGINX and Certbot

```bash
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y
```

### Configure NGINX Reverse Proxy

Create the ArgoCD proxy configuration:

```bash
sudo nano /etc/nginx/sites-available/argocd
```

Add the following:

```
server {
   listen 80;
   server_name <your-domain>;

   location / {
       proxy_pass https://localhost:8080;
       proxy_ssl_verify off;
       proxy_http_version 1.1;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
   }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/argocd /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Generate SSL Certificate

Run Certbot:

```bash
sudo certbot --nginx -d <your-domain>
```

Follow the prompts. Certbot will automatically update NGINX to enable HTTPS.

---

## Step 3: Configure GitHub OAuth Application

1. Log into GitHub and navigate to:
   **Settings → Developer Settings → OAuth Apps**
2. Select **New OAuth App** and provide:

   * **Application Name:** ArgoCD
   * **Homepage URL:** `https://<your-domain>`
   * **Authorization Callback URL:**
     `https://<your-domain>/api/dex/callback`
3. Register the application.
4. Copy the generated **Client ID** and **Client Secret** for later use.

---

## Step 4: Deploy ArgoCD on Kubernetes

### Create ArgoCD Namespace

```bash
kubectl create namespace argocd
```

### Install ArgoCD

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Verify the resources:

```bash
kubectl -n argocd get all
```

### Expose the ArgoCD Server via NodePort

Edit the ArgoCD service:

```bash
kubectl -n argocd edit service argocd-server
```

Modify:

```
type: NodePort
```

Confirm the update:

```bash
kubectl -n argocd get all
```

---

## Step 5: Configure ArgoCD for GitHub SSO

Edit the ArgoCD ConfigMap:

```bash
kubectl -n argocd edit configmap argocd-cm
```

Update the SSO configuration. Insert your GitHub **Client ID**, **Client Secret**, **redirectURI**, and **OAuth URL** accordingly.

Restart the ArgoCD server:

```bash
kubectl -n argocd rollout restart deployment argocd-server
```

---

## Step 6: Access ArgoCD Using GitHub SSO

### Port-forward if needed:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Navigate in your browser to:

```
https://<your-domain>
```

You should now see the **"LOG IN VIA GITHUB"** option.
Proceed through GitHub authorization to access the ArgoCD dashboard.

You may also verify SSL by clicking the lock icon in the browser address bar.

---

## Conclusion

By integrating GitHub SSO with ArgoCD, you have established a secure, centralized authentication mechanism aligned with modern DevOps security best practices. This setup enhances user access management, reduces credential overhead, and enables seamless sign-in workflows using GitHub as a trusted identity provider.

