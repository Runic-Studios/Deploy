kustomize build --enable-helm . | kubectl apply --server-side --force-conflicts -f -
