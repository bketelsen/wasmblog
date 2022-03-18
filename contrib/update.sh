#!/bin/bash

cd /opt/spin/wasmblog && git pull && chown -R spin:spin .
systemctl restart bartholomew.service
sleep 10
systemctl restart bartholomew2.service
