# Azure Workshop - Environment Setup Instructions

## Prerequisites for Workshop Participants

To get the most out of this workshop, participants should have the following tools and access ready before the workshop begins:

### Required Access
- An Azure subscription with Owner or Contributor permissions
- Ability to create resources in Azure (including AKS clusters, virtual networks, etc.)
- Ability to create Azure AD applications (for AKS integration)

### Required Software
1. **Azure CLI**
   - Windows: [Download installer](https://aka.ms/installazurecliwindows)
   - macOS: `brew install azure-cli`
   - Linux: [Installation instructions](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux)

2. **Terraform CLI** (version 1.0.0 or later)
   - Windows: [Download installer](https://www.terraform.io/downloads.html)
   - macOS: `brew install terraform`
   - Linux: [Installation instructions](https://learn.hashicorp.com/tutorials/terraform/install-cli)

3. **Git Client**
   - Windows: [Download installer](https://git-scm.com/download/win)
   - macOS: `brew install git` or included with Xcode Command Line Tools
   - Linux: `apt-get install git` or `yum install git`

4. **Visual Studio Code**
   - [Download for all platforms](https://code.visualstudio.com/download)
   - Recommended extensions:
     - Azure Terraform
     - Kubernetes
     - YAML
     - Azure Account

5. **Kubernetes CLI (kubectl)**
   - Windows: `az aks install-cli`
   - macOS: `brew install kubernetes-cli`
   - Linux: `az aks install-cli`

### Optional Software
- Docker Desktop (for local container testing)
- Azure Storage Explorer (for examining storage resources)
- Postman (for API testing)

## Pre-Workshop Setup

1. **Verify Azure Access**
   ```bash
   az login
   az account show
   ```

2. **Verify Terraform Installation**
   ```bash
   terraform version
   ```

3. **Verify kubectl Installation**
   ```bash
   kubectl version --client
   ```

4. **Clone the Workshop Repository**
   ```bash
   git clone https://github.com/zenigmadev/workshop.git
   cd azure-workshop
   ```
   Note: The actual repository URL will be provided before the workshop.

5. **Check Azure Resource Provider Registration**
   ```bash
   az provider register --namespace Microsoft.ContainerService
   az provider register --namespace Microsoft.Network
   az provider register --namespace Microsoft.OperationalInsights
   ```
6. **Create Service Principal**
   ```bash
   az ad sp create-for-rbac
   ```

## Resource Requirements

Ensure your Azure subscription has sufficient quota for:
- At least 12 vCPUs for AKS nodes
- Standard_DS2_v2 and Standard_DS3_v2 VM sizes
- At least 10 public IP addresses
- At least 5 virtual networks

## Troubleshooting Common Issues

### Azure CLI Login Issues
- If you're using a corporate account, you might need to use device code authentication:
  ```bash
  az login --use-device-code
  ```

### Terraform Provider Issues
- If you encounter provider version issues, run:
  ```bash
  terraform init -upgrade
  ```

### AKS Creation Issues
- If AKS creation fails due to quota limits, request a quota increase or use a different region
- If you encounter permission issues, ensure your account has the "Owner" or "Contributor" role

## Support

If you encounter any issues during setup, please contact the workshop organizers at:
- Email: workshop@example.com
- Slack: #azure-workshop channel
