# syntax=docker/dockerfile:1.7

# --- Stage 1: Build ---
FROM eclipse-temurin:25-jdk-alpine AS build

WORKDIR /app

COPY gradlew settings.gradle.kts build.gradle.kts ./
COPY gradle ./gradle
COPY src ./src

RUN --mount=type=cache,target=/root/.gradle \
    ./gradlew --no-daemon clean bootJar -x test

# --- Stage 2: Runtime ---
FROM eclipse-temurin:25-jre-alpine

RUN addgroup -S spring \
    && adduser -S spring -G spring

WORKDIR /home/spring/app

COPY --from=build /app/build/libs/*.jar ./app.jar

ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError"

RUN chown -R spring:spring /home/spring
USER spring:spring

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health | grep -q '"status":"UP"'

ENTRYPOINT ["java", "-jar", "app.jar"]