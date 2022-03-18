#!/bin/bash

cp ./contrib/systemd/bartholomew.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable bartholomew.service
systemctl start bartholomew.service
systemctl status bartholomew.service
