#!/bin/bash

#
# This script runs for both combined instances and autoscaled instances. We will be passed in a variable
# ${instance_type} which will let us determine what we do.
#

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
add-apt-repository "deb http://archive.ubuntu.com/ubuntu bionic multiverse"
add-apt-repository "deb http://archive.ubuntu.com/ubuntu bionic-security multiverse"
add-apt-repository "deb http://archive.ubuntu.com/ubuntu bionic-updates multiverse"
add-apt-repository "deb http://archive.ubuntu.com/ubuntu bionic universe"
add-apt-repository "deb http://archive.ubuntu.com/ubuntu bionic-security universe"
add-apt-repository "deb http://archive.ubuntu.com/ubuntu bionic-updates universe"

apt-get update -y
apt-get install -y python3-pip docker-ce git apt-transport-https ca-certificates curl software-properties-common mysql-client-5.7
snap install yq

usermod -aG docker ubuntu
runuser -l ubuntu -c "pip3 install docker-compose --user"
runuser -l ubuntu -c "echo export PATH=$PATH:/home/ubuntu/.local/bin >> /home/ubuntu/.bashrc"

echo Cloning MTP...
cd /home/ubuntu
git clone https://github.com/barryw/MassTestingPlatform.git
echo Clone complete.

cd /home/ubuntu/MassTestingPlatform
cp .sample.env .env

chown -R ubuntu:ubuntu /home/ubuntu

runuser -l ubuntu -c "cd /home/ubuntu/MassTestingPlatform && docker-compose build --build-arg CERT_URL="

if [ "${instance_type}" = "autoscale" ]; then
  echo Configuring application server
  sed -i 's@DB_HOST=database:3306@DB_HOST=db.mtp.internal:3306@' /home/ubuntu/MassTestingPlatform/docker-compose.yml
  runuser -l ubuntu -c "yq d -i /home/ubuntu/MassTestingPlatform/docker-compose.yml 'services.database'"
  runuser -l ubuntu -c "yq d -i /home/ubuntu/MassTestingPlatform/docker-compose.yml 'services.application.depends_on'"
fi

sed -i 's/^SES_EMAIL_ADDRESS=.*$/SES_EMAIL_ADDRESS=${ses_from_email}/' /home/ubuntu/MassTestingPlatform/.env
sed -i 's/^SES_EMAIL_NAME=.*$/SES_EMAIL_NAME=${ses_from_name}/' /home/ubuntu/MassTestingPlatform/.env
sed -i 's/AWS_REGION=.*$/AWS_REGION=${region}/' /home/ubuntu/MassTestingPlatform/docker-compose.yml

runuser -l ubuntu -c "cd /home/ubuntu/MassTestingPlatform && docker-compose up -d"
export DB_USERNAME=$(grep DB_USERNAME /home/ubuntu/MassTestingPlatform/.env | cut -d '=' -f2)
export DB_PASSWORD=$(grep DB_PASSWORD /home/ubuntu/MassTestingPlatform/.env | cut -d '=' -f2)

while ! mysqladmin ping -h db.mtp.internal -u $DB_USERNAME -p$DB_PASSWORD --silent; do
  sleep 1
done

# Run the build step
docker exec mtp_app bin/build.sh
