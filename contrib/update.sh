#!/bin/bash

both='[{"dial": "localhost:3000"},{"dial": "localhost:3001"}]'
first='[{"dial": "localhost:3000"}]'
last='[{"dial": "localhost:3001"}]'

cd /opt/spin/wasmblog || exit
old_version="$(git rev-parse --short HEAD)"
git pull && chown -R spin:spin .
new_version="$(git rev-parse --short HEAD)"

if [ "$old_version" = "$new_version" ]; then
    echo "No changes"
    exit 0
else
    echo "Changes detected, restarting services"
    echo "Removing port 3000"
    curl -X PATCH \
        -H "Content-Type: application/json" \
        -d "$last" \
    "http://localhost:2019/config/apps/http/servers/srv0/routes/0/handle/0/routes/0/handle/0/upstreams"
    echo "restarting 3000"
    systemctl restart bartholomew.service
    sleep 10
    echo "Removing port 3001"
    curl -X PATCH \
        -H "Content-Type: application/json" \
        -d "$first" \
    "http://localhost:2019/config/apps/http/servers/srv0/routes/0/handle/0/routes/0/handle/0/upstreams"
    echo "restarting 3001"
    systemctl restart bartholomew2.service

    echo "enabling both"
    curl -X PATCH \
        -H "Content-Type: application/json" \
        -d "$both" \
    "http://localhost:2019/config/apps/http/servers/srv0/routes/0/handle/0/routes/0/handle/0/upstreams"
fi
