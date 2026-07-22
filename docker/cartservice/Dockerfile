FROM mcr.microsoft.com/dotnet/sdk:7.0 AS builder

WORKDIR /app

COPY src/cartservice .

RUN dotnet restore
RUN dotnet publish -c Release -o out

FROM mcr.microsoft.com/dotnet/runtime:7.0

WORKDIR /app

COPY --from=builder /app/out .

EXPOSE 7070

CMD ["dotnet", "cartservice.dll"]