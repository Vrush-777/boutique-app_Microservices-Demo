# Networking Module

## Purpose
Creates the network infrastructure for the boutique app deployment on Azure.

## What This Module Creates

### 1. Virtual Network (VNet)
- IP range: 10.0.0.0/16 (65,536 IP addresses)
- Container for all networking resources
- Example: `poc-vnet`

### 2. Public Subnet
- IP range: 10.0.1.0/24 (256 IP addresses)
- Purpose: Hosts the Application Load Balancer (ALB)
- Traffic: Can reach internet and be reached from internet
- Example: `poc-public-subnet`

### 3. Private Subnet
- IP range: 10.0.2.0/24 (256 IP addresses)
- Purpose: Hosts AKS Kubernetes nodes
- Traffic: Cannot be reached from internet (only outbound via NAT)
- Example: `poc-private-subnet`

### 4. Network Security Groups (NSGs)
NSGs are like firewalls for subnets. They control inbound and outbound traffic.

#### Public NSG Rules
| Rule | Port | Source | Purpose |
|------|------|--------|---------|
| AllowHTTPS | 443 | Internet | HTTPS web traffic |
| AllowHTTP | 80 | Internet | HTTP web traffic |
| AllowKubernetesAPI | 6443 | Internet | K8s management |

#### Private NSG Rules
| Rule | Source | Purpose |
|------|--------|---------|
| AllowVNetInbound | 10.0.0.0/16 | Internal VNet traffic |
| AllowPublicSubnetInbound | 10.0.1.0/24 | LB to AKS traffic |
| DenyAllInbound | Any | Default deny everything else |

### 5. NAT Gateway
- Allows private subnet to reach internet (for updates, etc.)
- All outbound traffic appears to come from NAT Gateway's public IP
- Keeps AKS nodes secure while allowing outbound connections

### 6. Internet Gateway
- Allows public subnet to reach internet
- Allows internet to reach public subnet (ALB)

## Network Architecture Diagram