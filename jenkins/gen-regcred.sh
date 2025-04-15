#!/bin/bash
set -euo pipefail

# Assumes you have a file named dockerconfig.json in current directory

kubectl create secret generic regcred \
  --namespace jenkins \
  --type kubernetes.io/dockerconfigjson \
  --from-file=.dockerconfigjson=dockerconfig.json \
  --dry-run=client \
  -o json > regcred.json

kubeseal \
  --format yaml \
  --cert ../secret/pub-cert.pem \
  --controller-name=sealed-secrets \
  --controller-namespace=sealed-secrets \
  < regcred.json > regcred-sealed.yaml
rm regcred.json

echo "Generated regcred-sealed.yaml"
