FROM gradle:8.14-jdk21 AS builder

WORKDIR /app

COPY src/adservice .

RUN chmod +x gradlew
RUN ./gradlew downloadRepos
RUN ./gradlew installDist

FROM eclipse-temurin:21-jre

WORKDIR /app

COPY --from=builder /app .

EXPOSE 9555

ENTRYPOINT ["/app/build/install/hipstershop/bin/AdService"]