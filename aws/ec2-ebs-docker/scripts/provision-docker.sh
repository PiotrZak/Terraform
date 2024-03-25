#!/bin/bash

# https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#install-using-the-convenience-script

# Download the docker
curl -fsSL get.docker.com -o get-docker.sh

# Superuser privelege
sudo sh get-docker.sh

# Remove script after executions
rm get-docker.sh

# Adding current user to the docker group
sudo usermod -aG docker $(whoami)

# https://success.docker.com/article/how-to-setup-log-rotation-post-installation

# Creates a JSON configuration file (/etc/docker/daemon.json) for the Docker daemon.
# Specifies the logging driver as "json-file", indicating that Docker should write container logs as JSON files.
# Sets options for log rotation, specifying a maximum log file size of 10 megabytes (max-size: "10m") and a maximum number of log files to retain (5 files in total, max-file: "5").

echo '{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5"
  }
}
' | sudo tee /etc/docker/daemon.json
sudo service docker restart # restart the daemon so the settings take effect