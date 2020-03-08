# gather
For harvesting latest repos

Once container is created, add id_rsagihub to ~/.ssh
and do git ls-remote for each of the forges to 
avoid yes/no question (alternatively, add options to config to prevent that)

A command line to start container on gcp
allow https
docker run -d -v /home/audris/gather:/data/gather -w /home/audris -p443:22 --name gather audris/gather /bin/startDef.sh audris
