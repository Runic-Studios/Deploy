#!/bin/bash
set -euo pipefail

# Assumes you have:
# - cloudflare.env file in current directory
# Format:
# CF_DNS_API_TOKEN=abc123
# CF_API_EMAIL=me@example.com

kubectl create secret generic cloudflare-api-token-secret \
  --namespace traefik \
  --from-env-file=cloudflare.env \
  --dry-run=client \
  -o json > cloudflare.json

kubeseal \
  --format yaml \
  --cert ../secret/pub-cert.pem \
  --controller-name=sealed-secrets \
  --controller-namespace=sealed-secrets \
  < cloudflare.json > cloudflare-sealed.yaml

rm cloudflare.json

echo "Generated cloudflare-sealed.yaml"
