# ==============================================================================
# CART SERVICE DOCKERFILE (C#/.NET)
# ==============================================================================

# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS builder

WORKDIR /app

# Copy project files
COPY src/cartservice/src/cartservice.csproj .

# Restore dependencies
RUN dotnet restore cartservice.csproj

# Copy source code
COPY src/cartservice/src/ .

# Build and publish
RUN dotnet publish -c Release -o /app/out

# ==============================================================================
# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/runtime:7.0

WORKDIR /app

# Copy compiled app from builder
COPY --from=builder /app/out .

EXPOSE 7070

# Run application
CMD ["dotnet", "cartservice.dll"]