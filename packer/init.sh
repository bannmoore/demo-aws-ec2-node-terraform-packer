#!/bin/bash

echo "Installing node and npm"
sudo apt-get -qq update
sudo apt-get -qq install --yes nodejs nodejs-legacy npm

echo "Installing dependencies"
cd /home/ubuntu
npm install --production --quiet