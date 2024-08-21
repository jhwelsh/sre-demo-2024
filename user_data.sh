#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
sudo systemctl start apache2
echo "Terraform Webserver Test Demo" | sudo tee /var/www/html/index.html

