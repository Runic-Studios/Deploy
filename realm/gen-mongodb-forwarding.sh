#!/bin/bash
set -euo pipefail

if [[ ! -f mongodb.secret ]]; then
  echo "Missing mongodb.secret file"
  exit 1
fi

SECRET_NAME="mongodb-secret"
TEMP_SECRET="mongodb.json"
SEALED_SECRET="./mongodb-secret-sealed.yaml"
NAMESPACES=("realm-dev" "realm")  # LIST ALL NAMESPACES

for ns in "${NAMESPACES[@]}"; do
  kubectl create secret generic "$SECRET_NAME" \
    --from-file=mongodb.secret=mongodb.secret \
    --namespace="$ns" \
    --dry-run=client \
    -o json > "$TEMP_SECRET"

  SEALED_SECRET="mongodb-secret-sealed-${ns}.yaml"
  kubeseal \
    --format yaml \
    --cert ../secret/pub-cert.pem \
    --controller-name=sealed-secrets \
    --controller-namespace=sealed-secrets \
    --scope namespace-wide \
    < "$TEMP_SECRET" > "$SEALED_SECRET"
  rm "$TEMP_SECRET"
  echo "Generated $SEALED_SECRET"
done
