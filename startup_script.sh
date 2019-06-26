#!/bin/bash

# Install Ruby
sudo apt update
sudo apt -y install ruby-full ruby-bundler build-essential

# Install Mongodb
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
sudo apt update
sudo apt -y install mongodb-org
sudo systemctl start mongod.service
sudo systemctl enable mongod.service

# Deploy testapp
cd ~
git clone -b monolith https://github.com/express42/reddit.git
cd reddit
bundle install
puma -d
