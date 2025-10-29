#!/bin/bash
# -----------------------------------------------
# 🧩 Kubernetes CSR Demo Script
# Author: <Your Name>
# Description: Demonstrates how to create, submit,
# approve, and extract a certificate in Kubernetes.
# -----------------------------------------------

set -e

echo " Step 1: Generating a private key..."
openssl genrsa -out adam.key 2048

echo " Step 2: Creating a Certificate Signing Request (CSR)..."
openssl req -new -key adam.key -out adam.csr -subj "/CN=adam"

echo " Step 3: Checking for existing Kubernetes CSRs..."
kubectl get csr || echo "No existing CSRs found."

echo " Step 4: Encoding CSR to Base64..."
CSR_BASE64=$(cat adam.csr | base64 | tr -d "\n")

echo " Step 5: Creating csr.yaml manifest..."
cat <<EOF > csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: adam
spec:
  request: "${CSR_BASE64}"
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 31536000  # 1 year
  usages:
  - client auth
EOF

echo " Step 6: Applying the CSR to Kubernetes..."
kubectl apply -f csr.yaml

echo " Step 7: Checking CSR status..."
kubectl get csr

echo " Step 8: Approving the CSR..."
kubectl certificate approve adam

echo " Step 9: Verifying CSR approval..."
kubectl get csr

echo " Step 10: Exporting the issued certificate details..."
kubectl get csr adam -o yaml > issuecert.yaml

echo " Step 11: Decoding the approved certificate..."
CERT_CONTENT=$(kubectl get csr adam -o jsonpath='{.status.certificate}')
echo "${CERT_CONTENT}" | base64 --decode > certificate.crt

echo " All done! CSR approved and certificate saved as certificate.crt"
echo " You can now add this cert to kubeconfig or use it for client authentication."
