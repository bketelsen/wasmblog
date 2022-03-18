#!/bin/bash

cp ./contrib/systemd/bartholomew.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable bartholomew.service
systemctl start bartholomew.service
systemctl status bartholomew.service

cp ./contrib/systemd/update-bart.service /etc/systemd/system/
cp ./contrib/systemd/update-bart.timer /etc/systemd/system/

systemctl enable update-bart.timer

systemctl restart update-bart.timer
