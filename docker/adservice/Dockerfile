FROM gradle:8.14-jdk21 AS builder

WORKDIR /app

COPY src/adservice .

RUN chmod +x gradlew && ./gradlew build --no-daemon


FROM eclipse-temurin:21-jre

WORKDIR /app

COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 9555

ENTRYPOINT ["java","-jar","app.jar"]