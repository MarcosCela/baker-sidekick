#!/bin/sh
set -e
echo "Copying JRE to volume..."
cp -R /shared-origin/. /shared/
echo "Correctly injected dependencies to /shared"