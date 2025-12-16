#!/bin/bash
set -euo pipefail

# Assumes you have two files in the current directory (Deploy/arc):
# - gh-app.env containing:
#   GITHUB_APP_ID=...
#   GITHUB_APP_INSTALLATION_ID=...
# - gh-app.pem containing the RSA private key

if [ ! -f gh-app.env ]; then
    echo "Error: gh-app.env not found. Please create gh-app.env with GITHUB_APP_ID and GITHUB_APP_INSTALLATION_ID."
    exit 1
fi

if [ ! -f gh-app.pem ]; then
    echo "Error: gh-app.pem not found. Please create gh-app.pem with your RSA private key."
    exit 1
fi

source gh-app.env

if [ -z "${GITHUB_APP_ID:-}" ]; then
    echo "Error: GITHUB_APP_ID not found in gh-app.env"
    exit 1
fi

if [ -z "${GITHUB_APP_INSTALLATION_ID:-}" ]; then
    echo "Error: GITHUB_APP_INSTALLATION_ID not found in gh-app.env"
    exit 1
fi

kubectl create secret generic arc-github-config \
  --namespace=arc-system \
  --from-literal=github_app_id="${GITHUB_APP_ID}" \
  --from-literal=github_app_installation_id="${GITHUB_APP_INSTALLATION_ID}" \
  --from-file=github_app_private_key=gh-app.pem \
  --dry-run=client \
  -o json > gh-app-secret-system.json

kubectl create secret generic arc-github-config \
  --namespace=arc-runners \
  --from-literal=github_app_id="${GITHUB_APP_ID}" \
  --from-literal=github_app_installation_id="${GITHUB_APP_INSTALLATION_ID}" \
  --from-file=github_app_private_key=gh-app.pem \
  --dry-run=client \
  -o json > gh-app-secret-runners.json

kubeseal \
  --format yaml \
  --cert ../secret/pub-cert.pem \
  --controller-name=sealed-secrets \
  --controller-namespace=sealed-secrets \
  < gh-app-secret-system.json > gh-app-sealed-system.yaml
rm gh-app-secret-system.json

echo "Generated gh-app-sealed-system.yaml"

kubeseal \
  --format yaml \
  --cert ../secret/pub-cert.pem \
  --controller-name=sealed-secrets \
  --controller-namespace=sealed-secrets \
  < gh-app-secret-runners.json > gh-app-sealed-runners.yaml
rm gh-app-secret-runners.json

echo "Generated gh-app-sealed-runners.yaml"