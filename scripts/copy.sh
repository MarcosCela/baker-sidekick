#!/usr/bin/env bash
set -e
echo "Copying JRE to volume..."
rm -rf /shared/*
cp -R /shared-origin/. /shared/
echo "Setting permission to bamboo user!"
chown -R bamboo:bamboo /shared/
echo "Correctly injected dependencies to /shared"