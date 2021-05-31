# Deploy Docker Container to AWS EC2 with Bitbucket Pipeline
In this tutorial, we will automatize the deployment steps of a simple web application docker container using the Bitbucket Pipeline feature. Some instructions are specific to the Maven Java project. If your project is not a Maven project, make appropriate changes.
## Goal
Whenever we push a commit into the Bitbucket repository, Pipeline will process the following steps;
1.	Build the project and create a jar file
2.	Create a Docker Image with the new jar and transfer it into the AWS ECR Repository
3.	Pull the latest Image from AWS ECR to EC2 instance and update the Docker container.
## What do we need?
*	A web application
*	**AWS IAM User** that has permissions to push Docker Image to AWS ECR and pull into AWS EC2
*	**AWS ECR (Elastic Container Registry)** Repository to store Docker Images
*	**AWS EC2 Instance (Virtual Service in Cloud)** that docker installed to serve the application
*	**Dockerfile** to create Docker Image that will be the template of the Docker container
*	**Shell Script** that creates/updates the docker container from the docker image
*	**YAML file** to configure Bitbucket Pipeline
*	**Bitbucket Repository** for resource control\
In case of your application is not ready for deployment, you can follow tutorial steps with the simple application that I created. Dockerfile, Shell Script, and YAML files have already included, you need the add your AWS services connection information. The tutorial shows where you can find this information.
[Example Project](https://github.com/Gorhem/spring-web-docker-deployment) 

## Create an AWS IAM User and configure
AWS IAM stands for Identity and Access Management, with it you can manage access to AWS services and resources. We will create a Group with the necessary policies to push the docker image to the ECR repository and pull it to the EC2 instance.\
Search IAM in AWS search bar → User Groups → Create group → Define a name for the group and save 

![IAM-User-groups](IAM-User-groups.png)
 
After creating a Group without user and policy we will click group name from the list to edit. Navigate to the **“Permissions”**** tab, click **“Add permissions”** and choose **“Create Inline Policy”**.

 ![IAM-Permissions](IAM-Permissions.png)

Navigate to the **“JSON”** tab and copy the below policy to yours. For the official guide [Repository policy examples]( https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policy-examples.html) 
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload"
            ],
            "Resource": "*"
        }
    ]
}
```
Click **“Review Policy”**, write a name, and click **“Create Policy”**.

Now we need a User that will have these privileges. Go to the IAM → User tab and click **“Add user”**. Specify a name and choose **“Programmatic access”** for access type. Click **“Next: Permissions”**.

 ![IAM-User-Access-type](access-type.png)

Choose the group you created then click **“Next: Tags”**. There is no need for a tag right now, click **“Next: Review”** then click **“Create user”**.\
AWS creates Access Key ID and Secret Access Key for your user. Click **“Download .csv”** and keep it. We will use this information in the Bitbucket Pipeline to push Docker Image to the AWS ECR repository.
## What is AWS ECR Repository?
It is Amazon Elastic Container Registry for storing, managing and deploying docker containers.

AWS ECR → Private tab → Create Repository, provide a name for repository then click **“Create repository”**. 

URI will be needed to access.

![ECR-Repository](ecr-repository.png)
 
## How to create EC2 Instance?
AWS EC2 → Instances → Launch instances 
Now you need to choose a Machine Image. Let’s choose Ubuntu Server Image.

 ![](ubuntu-image.png)

In the next step **“Choose an Intence Type”**, you need to choose the appropriate mix of resources. We will continue with t2.micro which is a free tier eligible type. Go to **“Configure Security Group”** tab we need to open 8080 port to the public. Click **“Add Rule”** and write 8080 into **“Port Range”**.

 ![](port-range.png)
 
Click **“Review and Launch”** then **“Launch”**. Choose **“Create a new key pair”** and write a name for your key pair that will be used to connect to the instance. Click **“Download Key Pair”**.

 ![](create-key-pair.png)
 
Now you have an instance running on the cloud you can monitor the state on the Instances page. Clicking the checkbox will make details display at bottom of the screen.

 ![](ec2-detail.png)
 
To SSH your instance you can use PuTTY. You need to convert **“.pem”** file to **“.ppk”** file to connect to your instance using PuTTY. When you install PuTTY provides a tool named PuTTYgen, which converts keys to the required format for PuTTY. Open PuTTYgen and make sure you have the right parameters then click load.

 ![](puttygen-pair-load.png)
 
Choose your downloaded **“.pem”** file by choosing the option **“All Files(*.*)”**. After successfully loaded click **“Save Private Key”**. You can close PuTTYgen.

Go back to your EC2 Instances list page and click **“Connect”**, navigate to **“SSH client”** then copy the last parameter of the example ssh command at the bottom of the page which is the combination of user and public DNS information. If you want you can use public DNS to connect and after connect enter the user name in the terminal.

Open PuTTY, paste into the **“Host Name”** field then go to Connection → SSH → Auth

 ![](putty-auth.png)
 
Browse and select **“.ppk”** file that you converted with PuTTYgen. Click **“Open”** which will open the terminal of your instance.

### Prepare instance for deployment;
1.	sudo apt update // Update package repository
2.	Install Docker with followed commands;
  *	sudo apt install docker.io
  *	sudo usermod -a -G docker ubuntu // With this you can execute docker command without using sudo. **You need to close the current ssh session and connect again to activate.**
3.	Install Python pip to use installing AWS CLI;
  *	sudo apt install python3-pip // Install pip
4.	Install AWS CLI to use aws commands;
*	sudo pip install awscli --force-reinstall --upgrade // Install latest version AWS CLI
*	aws configure
    - Enter your AWS Access Key ID from the downloaded **“.csv”** file
    -	Enter your AWS Secret Key from the downloaded **“.csv”** file
    -	Enter default region name, the subdomain of your ECR Repository URI (dkr.ecr.us-east-2.amazonaws.com)or subdomain of AWS console URI (us-east-2.console.aws.amazon.com) is your region. That is → **“us-east-2”** in this example.
    -	No need to provide **“output format”** press enter

Your EC2 Instance ready for deployment.

## What is Docker Container? Why do we need Dockerfile?
Docker Container is a runnable instance of an image that is a read-only template with instructions. So we need to create an image of our application. In docker, an image is based on another image. Since the application we have is a java application, it should be based on a JDK(Java Development Kit) image. You can find base images that suitable for your application from [DockerHub](https://hub.docker.com/search?q=&type=image&image_filter=official). 

A Dockerfile is a text document that contains commands that we need to create a Docker Image. You should add a Dockerfile without extension in your project root directory. This file will be used by Bitbucket Pipeline.

Dockerfile contains followed commands:

 ![](dockerfile.png)
 
**FROM** command defines the image that will be used as a base. The example application needs JDK version 8 so, we add 8 after the colon to specify the version number.

As a web application, we need a port for upcoming requests. With **EXPOSE** command container will listens specific port.

The example project is a Maven project, to run our project Maven will create a jar file that can be runnable in any JDK installed machine. **ADD** command will add that jar file into our docker image. The first parameter of ADD command is the default path of the jar file located after run **“mvn install”** command. The second parameter is what will be the name of the jar in the image. For the customize created jar name you can add **“fileName”** tag in **“build”** tag as shown below. **Be careful if you do that you should update your Dockerfile ADD command’s first parameter.**

 ![](pom.png)
 
And lastly, we have **ENTRYPOINT** command that will execute our jar file when the container starts running. 

After pushing our project into Bitbucket with this complete Dockerfile, we will create an image.

## Let’s write the Shell Script
Create a file in your project root folder with the name **“deployment.sh”**. **If you use another name, use same name while writing YAML (.yml) file.**

With this script, we will pull the latest Docker Image from ECR repository and run a Docker container with it. To perform that script must have the following steps.

*	Authenticate your EC2 instance to the ECR repository

    When you choose the ECR repository that just created and click **“View push commands”**. You can directly copy and use the given script in the first step. 

     ![](ecr-auth-script.png)
 
*	Pull docker image from ECR repository to EC2 instance

    The copied script will authenticate your EC2 Instance to the ECR repository after that you can be able to use **“docker pull”** command successfully. For **“docker pull”** command, you can copy URI from the ECR repository list page and put **“:latest”** at the end of it. **Do not forget to add **“sudo”** before docker to gain root privilege.**
```sh  
#!/bin/bash
aws ecr get-login-password --region us-east-2 | sudo docker login --username AWS --password-stdin {this-part-unique-to-you}.dkr.ecr.us-east-2.amazonaws.com

sudo docker pull {this-part-unique-to-you}.dkr.ecr.us-east-2.amazonaws.com/spring-web:latest
```
*	Run a Docker Container with Image

    When successfully pull the image from ECR to your EC2 instance you can use **“docker run”** command and create your container. While creating the container you need to make some specifications;
    1.	To set the name of the container **“--name container-name-you-decide”**
    2.	To link machine port to the container port **“-p 8080:8080”** with that when you send a request to 8080 port of your cloud instance, it will reach the container’s 8080 port which is the application listens
    3.	To start the container in the detached mode which means runs in the background of your terminal **“-d”**
    4.	And of course, you must provide your image name that is the same as the repository URI used in **“docker pull”** command. **“{this-part-unique-to-you}.dkr.ecr.us-east-2.amazonaws.com/spring-web:latest”**

So final script will be; (You can copy and make changes to use)
```sh
#!/bin/bash
aws ecr get-login-password --region us-east-2 | sudo docker login --username AWS --password-stdin {this-part-unique-to-you}.dkr.ecr.us-east-2.amazonaws.com
sudo docker pull {this-part-unique-to-you}.dkr.ecr.us-east-2.amazonaws.com/spring-web:latest
sudo docker run --name my-container-name -p 8080:8080 -d {this-part-unique-to-you}.dkr.ecr.us-east-2.amazonaws.com/spring-web:latest
```

## What is a Bitbucket pipelines?
""Bitbucket Pipelines"" is an integrated CI/CD service built into Bitbucket. It allows you to automatically build, test, and deploy your code based on a configuration file in your repository. 

To define pipeline we will create **“bitbucket-pipelines.yml”** file in the project root directory. In this pipeline, we will define the steps need to perform for deploying the application into AWS EC2 instance.

Before writing the steps pipeline require a template image. At the top, we provide a **“maven”** image according to our project type. 5 line defines name of the pipeline.
1.	In the first step, we are creating a jar by running mvn commands and define produced files as **“artifacts”** that will give us the ability to access them in another step.
2.	In the second step, we are creating Docker Image with the **“docker build”** command then push the image to ECR repository with the help of the pipe which Atlassian provides. We need to give ECR connection information as parameters to this pipe to push the created image. 
3.	And lastly, we will give EC2 instance connection as parameters to another Atlassian pipe that will run **“deployment.sh”** script in EC2 instance.

We will define connection information in Bitbucket for security reasons.

```yml
image: maven:3.6.3

pipelines:
  custom:
    deploy-to-ec2:
      - step:
          script:
            - mvn clean install
          artifacts:
            - target/**
      - step:
          deployment: Test
          script:
            - docker build ./ -t $AWS_ECR_REPOSITORY --build-arg ENV=dev
            - pipe: "atlassian/aws-ecr-push-image:1.1.0"
              variables:
                AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
                AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
                AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION
                IMAGE_NAME: $AWS_ECR_REPOSITORY
            - pipe: "atlassian/ssh-run:0.2.4"
              variables:
                SSH_USER: ubuntu
                SERVER: $SERVER_IP
                SSH_KEY: $SSH_KEY
                MODE: script
                COMMAND: deployment.sh
```

## How to define Pipeline Variables?
Create a repository and go to **“Repository settings”** → **“Settings”** under PIPELINES then click **“Enable Pipelines”**. Open **“Repository variables**“ under PIPELINES from the side menu.

Add the following variables;

*	AWS_ECR_REPOSITORY → ECR Repository name
*	AWS_ACCESS_KEY_ID → Access Key ID of your User, you can copy it from the downloaded **“.csv”** file
*	AWS_SECRET_ACCESS_KEY → Secret Access Key of your User, you can copy it from the downloaded **“.csv”** file
*	AWS_DEFAULT_REGION → Subdomain of your ECR Repository URI (dkr.ecr.us-east-2.amazonaws.com)or subdomain of AWS console URI (us-east-2.console.aws.amazon.com) is your region. That is → **“us-east-2”** in this example.
*	SERVER_IP → EC2 Instance Public Ip. You can find it on the **“Instances”** page on AWS by selecting your instance.
*	SSH_KEY → To obtain a valid formatted private key, open PuTTYgen, click **“Load”**, and choose your **“.ppk”** file that is created earlier to connect EC2 Instance. From the top menu choose **“Conversions”** → **“Export OpenSSH Key”**. Give a name to the file and add the **“.pem”** extension. Open created **“.pem”** file with a text editor and copy content then convert it to base64 string. You can use any online base64 encode tool.


## How to add the project to Bitbucket?
If your project has no source control, open terminal on the root directory of your project and writes these commands respectively;

*	**git init** // Initialize the directory under source control
*	**git add .** // Add the existing files to the repository
*	**git commit -m “Initialize Commit”** // Commit the files
*	Open repository page in Bitbucket and click **“Clone”** then copy the last part of the displayed command which is the address of the repository
*	**git remote add origin { you will paste the address in here}** // This comment will set your remote repository
*	**git pull origin master --allow-unrelated-histories**// incase of occurred any commit while creating the repository we need to pull first.

If there is any conflict;

*	**git checkout --ours .** // Use this command to resolve.
*	**git add .** // Add affected files.
*	**git commit -m “Merge”** // Commit merged files.
Lastly;
*	**git push -u origin master** // Push project to the repository

## Test Deployment
With using Public Ip or Public DNS of the EC2 Instance make an HTTP request to port 8080.

`https://Your-public-ip:80809`

Server Response:

**"Your application has been successfully deployed!"**
