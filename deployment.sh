#!/bin/bash
aws ecr get-login-password --region us-east-2 | sudo docker login --username AWS --password-stdin 257564702288.dkr.ecr.us-east-2.amazonaws.com
sudo docker pull 257564702288.dkr.ecr.us-east-2.amazonaws.com/spring-web:latest
sudo docker run --name my-container -d -p 8080:8080 257564702288.dkr.ecr.us-east-2.amazonaws.com/spring-web:latest
