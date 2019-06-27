#!/bin/bash

gcloud compute instances create reddit-base\
  --image reddit-base-1561651318 \
  --machine-type=g1-small \
  --zone europe-west1-d \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=deploy.sh
