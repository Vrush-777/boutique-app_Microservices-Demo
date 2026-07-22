FROM openjdk:21-slim

WORKDIR /app

COPY src/adservice .

RUN ./gradlew build -x test || true

EXPOSE 9555

CMD ["java", "-jar", "build/libs/adservice.jar"]