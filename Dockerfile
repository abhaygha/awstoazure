FROM maven:3.9.6-eclipse-temurin-17 AS build
COPY . /home/app
RUN mvn -f /home/app/pom.xml clean test package

FROM eclipse-temurin:17-jdk-alpine
COPY --from=build /home/app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
