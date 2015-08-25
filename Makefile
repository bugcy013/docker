#-This has been modelled off of jupyter/docker-demo-images (https://github.com/jupyter/docker-demo-images.git)-#

images: 
	quantecon

quantecon:
	docker build -t sanguineturtle/quantecon .

upload: images
	docker push sanguineturtle/quantecon

super-nuke: nuke
	-docker rmi sanguineturtle/quantecon

# Cleanup with fangs
nuke:
	-docker stop `docker ps -aq`
	-docker rm -fv `docker ps -aq`
	-docker images -q --filter "dangling=true" | xargs docker rmi

.PHONY: nuke
