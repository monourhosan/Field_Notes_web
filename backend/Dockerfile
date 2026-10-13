# Stage 1: Build the Spring Boot application using Maven and Java 21
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app

# Cache dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build package
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Minimal runtime image
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

# Copy built JAR from build stage
COPY --from=build /app/target/field-notes-backend-*.jar app.jar

EXPOSE 8080
ENV SERVER_PORT=8080

ENTRYPOINT ["java", "-jar", "app.jar"]
