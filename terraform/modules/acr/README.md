# Container Registry Module

## Purpose
Creates and configures Azure Container Registry (ACR) for storing Docker images.

## What is Azure Container Registry (ACR)?

ACR is a private Docker image registry hosted on Azure. Think of it like a private Docker Hub.

### Use Cases
1. **Store application images** - Frontend, services, workers
2. **Private images** - Not visible to the public
3. **CI/CD integration** - Automatically build and push images
4. **AKS integration** - Kubernetes pulls images securely
5. **Image scanning** - Detect vulnerabilities before deployment

### Image Repository Examples