#!/bin/bash

cp ./contrib/systemd/bartholomew.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable bartholomew.service
systemctl start bartholomew.service
systemctl status bartholomew.service

cp ./contrib/systemd/bartholomew2.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable bartholomew2.service
systemctl start bartholomew2.service
systemctl status bartholomew2.service

cp ./contrib/systemd/update-bart.service /etc/systemd/system/
cp ./contrib/systemd/update-bart.timer /etc/systemd/system/

systemctl enable update-bart.timer

systemctl restart update-bart.timer

cp ./contrib/caddy/Caddyfile /etc/caddy/
chown -R root:root /etc/caddy/

systemctl restart caddy.service

