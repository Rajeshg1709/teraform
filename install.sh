#!/bin/bash
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	   $(lsb_release -cs) \
	      stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo docker run -e MYSQL_ROOT_PASSWORD=welcome123 -e MYSQL_DATABASE=wordpress -e MYSQL_USER=ec2user -e MYSQL_PASSWORD=welcome123 --name wordpressdb -v "$PWD/database":/var/lib/mysql -d mariadb
sudo docker run -e WORDPRESS_DB_PASSWORD=welcome123 --name wordpress --link wordpressdb:mysql -p 80:80 -v "$PWD/html":/var/www/html -d wordpress
