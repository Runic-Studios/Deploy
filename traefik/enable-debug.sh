kubectl patch deployment traefik -n traefik \
  --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--log.level=DEBUG"}]'
