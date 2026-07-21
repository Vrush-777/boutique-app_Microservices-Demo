# Azure Kubernetes Service (AKS) Module

## Purpose
Creates and configures an Azure Kubernetes Service cluster for running containerized applications.

## What is AKS?

AKS = **Managed Kubernetes Service on Azure**

### Key Benefits
- **Managed Control Plane** - Azure manages master nodes, upgrades, patches
- **Auto-Scaling** - Automatically add/remove nodes based on demand
- **Integrated Security** - Azure AD integration, network policies, RBAC
- **Cost-Effective** - Pay only for worker nodes, not control plane
- **Production-Ready** - Used by enterprises running mission-critical apps

### What Gets Managed by Azure (You Don't Manage)
- Kubernetes API Server
- etcd (state database)
- Scheduler
- Controller Manager
- System components (DNS, proxy, etc.)
- Security updates and patches

### What You Manage
- Application deployments (using kubectl or GitOps)
- Node pool configuration
- Cluster resources (CPU, memory, storage)
- Monitoring and logging
- RBAC policies for users

## Architecture Overview