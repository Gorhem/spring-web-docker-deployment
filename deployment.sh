#!/bin/bash
aws ecr get-login-password --region us-east-2 | sudo docker login --username AWS --password-stdin {this-part-unique-to-you}.dkr.ecr.us-east-2.amazonaws.com
sudo docker pull {this-part-unique-to-you}.dkr.ecr.us-east-2.amazonaws.com/spring-web:latest
sudo docker run --name my-container-name -p 8080:8080 -d {this-part-unique-to-you}.dkr.ecr.us-east-2.amazonaws.com/spring-web:latest
