FROM openjdk:latest
EXPOSE 8080
ADD ./target/spring-docker-0.0.1-SNAPSHOT.jar spring-web-docker-in-image.jar
ENTRYPOINT ["java","-jar", "/spring-web-docker-in-image.jar"]
