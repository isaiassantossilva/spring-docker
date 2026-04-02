# --- Stage 1: Build ---
FROM gradle:9.4.1-jdk25-alpine AS build

WORKDIR /app

COPY build.gradle.kts settings.gradle.kts ./
COPY src ./src

RUN gradle clean build -x test

# --- Stage 2: Runtime ---
FROM eclipse-temurin:25-jre-alpine

RUN addgroup -S spring && adduser -S spring -G spring

WORKDIR /home/spring/app

COPY --from=build /app/build/libs/app.jar ./app.jar

RUN chown -R spring:spring /home/spring
USER spring:spring

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]