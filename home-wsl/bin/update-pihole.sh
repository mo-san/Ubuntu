yamlpath="/home/$USER/docker/pihole/docker-compose.yml"
image="pihole/pihole"

docker-compose -f "$yamlpath" down
docker image rm "$image"
docker-compose -f "$yamlpath" up -d
