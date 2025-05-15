docker system prune -f
docker stop $(docker ps -q)
docker rm $(docker ps -aq)
docker image prune -a -f
ctr images prune --all
