#!/bin/bash

cd /opt/spin/wasmblog || exit
old_version="$(git rev-parse --short HEAD)"
git pull && chown -R spin:spin .
new_version="$(git rev-parse --short HEAD)"

if [ "$old_version" = "$new_version" ]; then
    echo "No changes"
    return
else
    echo "Changes detected, restarting services"
    systemctl restart bartholomew.service
    sleep 10
    systemctl restart bartholomew2.service
fi
