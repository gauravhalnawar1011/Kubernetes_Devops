#!/bin/bash

ARGOCD_SERVER="your-server_address"
ADMIN_PASS="your_admin_pass"

# Log in as admin
argocd login $ARGOCD_SERVER --username admin --password "$ADMIN_PASS" --insecure

# Set passwords for users
argocd account update-password \
  --account developer \
  --current-password "$ADMIN_PASS" \
  --new-password "Developer123!"

argocd account update-password \
  --account devops \
  --current-password "$ADMIN_PASS" \
  --new-password "DevOps123!"

argocd account update-password \
  --account tester \
  --current-password "$ADMIN_PASS" \
  --new-password "Tester123!"
