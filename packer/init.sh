#!/bin/bash

echo "Updating software"
sudo yum -y update

echo "Installing node and npm"
curl --silent --location https://rpm.nodesource.com/setup_8.x | sudo bash -
sudo yum -y install nodejs

echo "Installing dependencies"
cd /home/ec2-user
npm install --production --quiet