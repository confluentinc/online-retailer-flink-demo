# Use Maven and JDK base image
FROM maven:3.9.9-eclipse-temurin-21

# Set the working directory inside the container
WORKDIR /opt/payments_app

# Copy all the project files into the container's working directory
COPY . .

# Run Maven to clean and package the project
RUN mvn compile

# Specify the command to run the Java application
CMD ["mvn", "exec:java"]

