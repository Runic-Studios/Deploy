#!/bin/bash
set -euo pipefail

# Assumes you have two files in the current directory (Deploy/argocd):
# - gh-pat.env containing:
#   GITHUB_PAT=...

if [ ! -f gh-pat.env ]; then
    echo "Error: gh-pat.env not found. Please create gh-pat.env with GITHUB_PAT."
    exit 1
fi

source gh-pat.env

if [ -z "${GITHUB_PAT:-}" ]; then
    echo "Error: GITHUB_PAT not found in gh-pat.env"
    exit 1
fi

kubectl create secret generic gh-pat-secret \
  --namespace=argocd \
  --from-literal=gh_pat="${GITHUB_PAT}" \
  --dry-run=client \
  -o json > gh-pat-secret.json

kubeseal \
  --format yaml \
  --cert ../secret/pub-cert.pem \
  --controller-name=sealed-secrets \
  --controller-namespace=sealed-secrets \
  < gh-pat-secret.json > gh-pat-sealed.yaml
rm gh-pat-secret.json

echo "Generated gh-pat-sealed.yaml"