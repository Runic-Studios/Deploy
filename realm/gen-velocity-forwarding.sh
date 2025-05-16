#!/bin/bash
set -euo pipefail

if [[ ! -f forwarding.secret ]]; then
  echo "Missing forwarding.secret file"
  exit 1
fi

SECRET_NAME="velocity-forwarding-secret"
TEMP_SECRET="velocity.json"
SEALED_SECRET="./forwarding-secret-sealed.yaml"
NAMESPACES=("realm-dev" "realm")  # LIST ALL NAMESPACES

for ns in "${NAMESPACES[@]}"; do
  kubectl create secret generic "$SECRET_NAME" \
    --from-file=forwarding.secret=forwarding.secret \
    --namespace="$ns" \
    --dry-run=client \
    -o json > "$TEMP_SECRET"

  SEALED_SECRET="forwarding-secret-sealed-${ns}.yaml"
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
