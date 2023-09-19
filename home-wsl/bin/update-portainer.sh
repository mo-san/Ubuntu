yamlpath="/home/$USER/docker/portainer/docker-compose.yml"
image="portainer/portainer-ce"

docker-compose -f "$yamlpath" down
docker image rm "$image"
docker-compose -f "$yamlpath" up -d
