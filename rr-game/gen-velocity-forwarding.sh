#!/bin/bash
set -euo pipefail

if [[ ! -f forwarding.secret ]]; then
  echo "Missing forwarding.secret file"
  exit 1
fi

SECRET_NAME="velocity-forwarding-secret"
TEMP_SECRET="velocity.json"
SEALED_SECRET="./forwarding-secret-sealed.yaml"

# Omit namespace here so it's not baked into the encryption
kubectl create secret generic "$SECRET_NAME" \
  --from-file=forwarding.secret=forwarding.secret \
  --dry-run=client \
  -o json > "$TEMP_SECRET"

kubeseal \
  --format yaml \
  --cert ../secret/pub-cert.pem \
  --controller-name=sealed-secrets \
  --controller-namespace=sealed-secrets \
  --scope cluster-wide \
  < "$TEMP_SECRET" > "$SEALED_SECRET"

rm "$TEMP_SECRET"

echo "Generated $SEALED_SECRET"
