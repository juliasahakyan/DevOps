#!/bin/bash
apt update -y
apt install nginx
systemctl status nginx
IP=$(curl -s http://icanhazip.com)
echo "Your URL is http://$IP"
