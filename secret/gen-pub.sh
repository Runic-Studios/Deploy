#!/bin/bash

kubeseal --fetch-cert \
  --controller-name=sealed-secrets \
  --controller-namespace=sealed-secrets \
  > pub-cert.pem
echo "Generated pub-cert.pem"
