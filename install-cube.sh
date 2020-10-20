#!/bin/bash

if [ $# -lt 1 ]; then
  cat <<EOS
Usage:
  ./install-cube.sh PASSWORD

Arguments:
  PASSWORD    # Password to set for Jupyter login
EOS
exit 1
fi

PASSWORD="${1}"

set -ex
# Log start time
echo "Started $(date)"

# Install our dependencies
export DEBIAN_FRONTEND=noninteractive
curl -fsSL https://download.docker.com/linux/ubuntu/gpg > docker.gpg
apt-get update
apt-key add docker.gpg 
apt-key list
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update && apt-get install -y docker-ce python3-pip unzip wget
pip3 install docker-compose

# Get our code
wget https://github.com/aogeodh/aogeodh-cube-in-a-box/archive/main.zip -O /tmp/archive.zip
unzip /tmp/archive.zip
mv aogeodh-cube-in-a-box /opt/odc

# We need to change some local vars.
sed --in-place "s/secretpassword/${PASSWORD}/g" /opt/odc/docker-compose.yml

# We need write access in these places
chmod -R 777 /opt/odc/notebooks
cd /opt/odc

# Start the machines
docker-compose up -d

# Wait for them to wake up
sleep 5

# Initialise and load a product, and then some data
# Note to future self, we can't use make here because of TTY interactivity (the -T flag)
# Initialise the datacube DB
docker-compose exec -T jupyter datacube -v system init
# Add some custom metadata
docker-compose exec -T jupyter datacube metadata add /scripts/metadata.eo_plus.yaml

echo "Finished $(date)"
