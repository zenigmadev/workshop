# Lab 4: Terraform ile Landing Zone Kurulumu

Bu lab çalışmasında, Terraform kullanarak Azure Landing Zone dağıtımı gerçekleştireceksiniz. Infrastructure as Code (IaC) yaklaşımıyla landing zone bileşenlerini oluşturacak ve yapılandıracaksınız.

## Ön Koşullar

- Azure hesabı (ücretsiz deneme hesabı yeterlidir)
- Web tarayıcı (Chrome, Edge veya Firefox güncel sürüm)
- Global Administrator veya User Access Administrator rolü
- Terraform CLI (en son sürüm)
- Git
- VS Code veya tercih edilen metin editörü

## Adım 1: Geliştirme Ortamını Hazırlama

### Terraform CLI Kurulumu

1. Terraform CLI'yi indirin ve kurun:
   - Windows: [Terraform Windows İndirme Sayfası](https://www.terraform.io/downloads.html)
   - macOS: `brew install terraform`
   - Linux: 
     ```bash
     wget https://releases.hashicorp.com/terraform/1.7.4/terraform_1.7.4_linux_amd64.zip
     unzip terraform_1.7.4_linux_amd64.zip
     sudo mv terraform /usr/local/bin/
     ```

2. Kurulumu doğrulayın:
   ```bash
   terraform version
   ```

### Azure CLI Kurulumu

1. Azure CLI'yi indirin ve kurun:
   - Windows: [Azure CLI Windows İndirme Sayfası](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows)
   - macOS: `brew install azure-cli`
   - Linux: 
     ```bash
     curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
     ```

2. Kurulumu doğrulayın:
   ```bash
   az version
   ```

3. Azure hesabınıza giriş yapın:
   ```bash
   az login
   ```

4. Aboneliğinizi seçin:
   ```bash
   az account set --subscription "Abonelik Adı veya ID"
   ```

## Adım 2: Terraform Projesi Oluşturma

1. Yeni bir proje dizini oluşturun:
   ```bash
   mkdir terraform-alz-workshop
   cd terraform-alz-workshop
   ```

2. Temel Terraform dosyalarını oluşturun:

   **providers.tf** dosyasını oluşturun:
   ```bash
   cat > providers.tf << 'EOF'
   terraform {
     required_providers {
       azurerm = {
         source  = "hashicorp/azurerm"
         version = "~> 3.74.0"
       }
       azuread = {
         source  = "hashicorp/azuread"
         version = "~> 2.46.0"
       }
     }
     required_version = ">= 1.3.0"
   }

   provider "azurerm" {
     features {
       resource_group {
         prevent_deletion_if_contains_resources = false
       }
     }
   }

   provider "azuread" {}

   data "azurerm_client_config" "current" {}
   EOF
   ```

   **variables.tf** dosyasını oluşturun:
   ```bash
   cat > variables.tf << 'EOF'
   variable "root_id" {
     type        = string
     description = "Root ID for the management group hierarchy"
     default     = "alz"
   }

   variable "root_name" {
     type        = string
     description = "Root name for the management group hierarchy"
     default     = "Azure Landing Zone"
   }

   variable "default_location" {
     type        = string
     description = "Default location for resources"
     default     = "westeurope"
   }

   variable "subscription_ids" {
     type = object({
       connectivity = string
       management   = string
       identity     = string
     })
     description = "Subscription IDs for the different landing zones"
   }
   EOF
   ```

   **terraform.tfvars** dosyasını oluşturun:
   ```bash
   cat > terraform.tfvars << 'EOF'
   root_id   = "alz"
   root_name = "Azure Landing Zone"

   default_location = "westeurope"

   subscription_ids = {
     connectivity = "00000000-0000-0000-0000-000000000000"
     management   = "00000000-0000-0000-0000-000000000000"
     identity     = "00000000-0000-0000-0000-000000000000"
   }
   EOF
   ```

   **main.tf** dosyasını oluşturun:
   ```bash
   cat > main.tf << 'EOF'
   # Management Groups Module
   module "management_groups" {
     source = "./modules/management_groups"

     root_id   = var.root_id
     root_name = var.root_name
   }

   # Log Analytics Workspace
   resource "azurerm_resource_group" "management" {
     name     = "rg-${var.root_id}-management"
     location = var.default_location
   }

   resource "azurerm_log_analytics_workspace" "management" {
     name                = "law-${var.root_id}-management"
     location            = azurerm_resource_group.management.location
     resource_group_name = azurerm_resource_group.management.name
     sku                 = "PerGB2018"
     retention_in_days   = 30
   }

   # Hub Network
   resource "azurerm_resource_group" "connectivity" {
     name     = "rg-${var.root_id}-connectivity"
     location = var.default_location
   }

   resource "azurerm_virtual_network" "hub" {
     name                = "vnet-${var.root_id}-hub"
     location            = azurerm_resource_group.connectivity.location
     resource_group_name = azurerm_resource_group.connectivity.name
     address_space       = ["10.0.0.0/16"]
   }

   resource "azurerm_subnet" "gateway" {
     name                 = "GatewaySubnet"
     resource_group_name  = azurerm_resource_group.connectivity.name
     virtual_network_name = azurerm_virtual_network.hub.name
     address_prefixes     = ["10.0.0.0/27"]
   }

   resource "azurerm_subnet" "firewall" {
     name                 = "AzureFirewallSubnet"
     resource_group_name  = azurerm_resource_group.connectivity.name
     virtual_network_name = azurerm_virtual_network.hub.name
     address_prefixes     = ["10.0.1.0/26"]
   }

   resource "azurerm_subnet" "management" {
     name                 = "snet-management"
     resource_group_name  = azurerm_resource_group.connectivity.name
     virtual_network_name = azurerm_virtual_network.hub.name
     address_prefixes     = ["10.0.2.0/24"]
   }

   # Policy Definitions and Assignments
   module "policy_definitions" {
     source = "./modules/policy_definitions"

     root_id = var.root_id
   }

   module "policy_assignments" {
     source = "./modules/policy_assignments"

     root_id                   = var.root_id
     log_analytics_workspace_id = azurerm_log_analytics_workspace.management.id
   }
   EOF
   ```

3. Modül dizinlerini ve dosyalarını oluşturun:

   ```bash
   mkdir -p modules/management_groups
   mkdir -p modules/policy_definitions
   mkdir -p modules/policy_assignments
   ```

   **modules/management_groups/main.tf** dosyasını oluşturun:
   ```bash
   cat > modules/management_groups/main.tf << 'EOF'
   resource "azurerm_management_group" "root" {
     display_name = var.root_name
     name         = var.root_id
   }

   resource "azurerm_management_group" "platform" {
     display_name               = "Platform"
     name                       = "${var.root_id}-platform"
     parent_management_group_id = azurerm_management_group.root.id
   }

   resource "azurerm_management_group" "landingzones" {
     display_name               = "Landing Zones"
     name                       = "${var.root_id}-landingzones"
     parent_management_group_id = azurerm_management_group.root.id
   }

   resource "azurerm_management_group" "sandbox" {
     display_name               = "Sandbox"
     name                       = "${var.root_id}-sandbox"
     parent_management_group_id = azurerm_management_group.root.id
   }

   resource "azurerm_management_group" "decommissioned" {
     display_name               = "Decommissioned"
     name                       = "${var.root_id}-decommissioned"
     parent_management_group_id = azurerm_management_group.root.id
   }

   resource "azurerm_management_group" "connectivity" {
     display_name               = "Connectivity"
     name                       = "${var.root_id}-connectivity"
     parent_management_group_id = azurerm_management_group.platform.id
   }

   resource "azurerm_management_group" "management" {
     display_name               = "Management"
     name                       = "${var.root_id}-management"
     parent_management_group_id = azurerm_management_group.platform.id
   }

   resource "azurerm_management_group" "identity" {
     display_name               = "Identity"
     name                       = "${var.root_id}-identity"
     parent_management_group_id = azurerm_management_group.platform.id
   }

   resource "azurerm_management_group" "corp" {
     display_name               = "Corp"
     name                       = "${var.root_id}-corp"
     parent_management_group_id = azurerm_management_group.landingzones.id
   }

   resource "azurerm_management_group" "online" {
     display_name               = "Online"
     name                       = "${var.root_id}-online"
     parent_management_group_id = azurerm_management_group.landingzones.id
   }
   EOF
   ```

   **modules/management_groups/variables.tf** dosyasını oluşturun:
   ```bash
   cat > modules/management_groups/variables.tf << 'EOF'
   variable "root_id" {
     type        = string
     description = "Root ID for the management group hierarchy"
   }

   variable "root_name" {
     type        = string
     description = "Root name for the management group hierarchy"
   }
   EOF
   ```

   **modules/policy_definitions/main.tf** dosyasını oluşturun:
   ```bash
   cat > modules/policy_definitions/main.tf << 'EOF'
   resource "azurerm_policy_definition" "require_resource_group_tags" {
     name         = "require-resource-group-tags"
     policy_type  = "Custom"
     mode         = "All"
     display_name = "Require resource group tags"
     description  = "This policy requires specified tags on resource groups."

     metadata = <<METADATA
     {
       "category": "Tags"
     }
     METADATA

     policy_rule = <<POLICY_RULE
     {
       "if": {
         "allOf": [
           {
             "field": "type",
             "equals": "Microsoft.Resources/subscriptions/resourceGroups"
           },
           {
             "field": "[concat('tags[', parameters('tagName'), ']')]",
             "exists": "false"
           }
         ]
       },
       "then": {
         "effect": "deny"
       }
     }
     POLICY_RULE

     parameters = <<PARAMETERS
     {
       "tagName": {
         "type": "String",
         "metadata": {
           "displayName": "Tag Name",
           "description": "Name of the tag, such as 'environment'"
         }
       }
     }
     PARAMETERS
   }

   resource "azurerm_policy_set_definition" "resource_tagging_initiative" {
     name         = "resource-tagging-initiative"
     policy_type  = "Custom"
     display_name = "Resource Tagging Initiative"
     description  = "This initiative enforces tagging requirements across resources and resource groups."

     metadata = <<METADATA
     {
       "category": "Tags"
     }
     METADATA

     policy_definition_reference {
       policy_definition_id = azurerm_policy_definition.require_resource_group_tags.id
       parameter_values     = <<VALUE
       {
         "tagName": {"value": "Environment"}
       }
       VALUE
     }
   }
   EOF
   ```

   **modules/policy_definitions/variables.tf** dosyasını oluşturun:
   ```bash
   cat > modules/policy_definitions/variables.tf << 'EOF'
   variable "root_id" {
     type        = string
     description = "Root ID for the management group hierarchy"
   }
   EOF
   ```

   **modules/policy_assignments/main.tf** dosyasını oluşturun:
   ```bash
   cat > modules/policy_assignments/main.tf << 'EOF'
   data "azurerm_management_group" "corp" {
     name = "${var.root_id}-corp"
   }

   resource "azurerm_management_group_policy_assignment" "resource_tagging_initiative" {
     name                 = "corp-tagging-initiative"
     policy_definition_id = "/providers/Microsoft.Management/managementGroups/${var.root_id}/providers/Microsoft.Authorization/policySetDefinitions/resource-tagging-initiative"
     management_group_id  = data.azurerm_management_group.corp.id
     description          = "Enforces tagging requirements for Corp landing zone."
     display_name         = "Corp Tagging Initiative"

     parameters = <<PARAMETERS
     {
       "tagName": {
         "value": "Environment"
       }
     }
     PARAMETERS
   }
   EOF
   ```

   **modules/policy_assignments/variables.tf** dosyasını oluşturun:
   ```bash
   cat > modules/policy_assignments/variables.tf << 'EOF'
   variable "root_id" {
     type        = string
     description = "Root ID for the management group hierarchy"
   }

   variable "log_analytics_workspace_id" {
     type        = string
     description = "Log Analytics Workspace ID"
   }
   EOF
   ```

4. `.gitignore` dosyasını oluşturun:
   ```bash
   cat > .gitignore << 'EOF'
   .terraform/
   *.tfstate
   *.tfstate.backup
   .terraform.lock.hcl
   EOF
   ```

## Adım 3: Terraform Yapılandırmasını Özelleştirme

1. `terraform.tfvars` dosyasını açın ve abonelik ID'lerinizi güncelleyin:
   ```bash
   # Abonelik ID'nizi öğrenmek için aşağıdaki komutu çalıştırın:
   az account show --query id -o tsv
   
   # Sonra terraform.tfvars dosyasını düzenleyin
   nano terraform.tfvars
   ```

2. Abonelik ID'lerinizi ve tercih ettiğiniz bölgeyi güncelleyin:
   ```hcl
   root_id   = "alz"
   root_name = "Azure Landing Zone"

   default_location = "westeurope"  # Tercih ettiğiniz bölgeyi seçin

   subscription_ids = {
     connectivity = "abonelik-id-nizi-buraya-yazin"  # Aynı abonelik ID'sini kullanabilirsiniz
     management   = "abonelik-id-nizi-buraya-yazin"  # Aynı abonelik ID'sini kullanabilirsiniz
     identity     = "abonelik-id-nizi-buraya-yazin"  # Aynı abonelik ID'sini kullanabilirsiniz
   }
   ```

## Adım 4: Terraform Dağıtımını Başlatma

1. Terraform çalışma dizinini başlatın:
   ```bash
   terraform init
   ```

2. Terraform planını oluşturun:
   ```bash
   terraform plan -out=tfplan
   ```

3. Planlanan değişiklikleri gözden geçirin ve dağıtımı başlatın:
   ```bash
   terraform apply tfplan
   ```

4. Dağıtım tamamlandığında, oluşturulan kaynakları doğrulayın:
   ```bash
   terraform output
   ```

## Adım 5: Spoke Virtual Network Ekleme

1. `main.tf` dosyasını açın ve Hub VNet'in altına aşağıdaki Spoke VNet yapılandırmasını ekleyin:
   ```bash
   nano main.tf
   ```

2. Aşağıdaki kodu ekleyin:
   ```hcl
   # Spoke Network
   resource "azurerm_resource_group" "spoke" {
     name     = "rg-${var.root_id}-spoke"
     location = var.default_location
   }

   resource "azurerm_virtual_network" "spoke" {
     name                = "vnet-${var.root_id}-spoke"
     location            = azurerm_resource_group.spoke.location
     resource_group_name = azurerm_resource_group.spoke.name
     address_space       = ["10.1.0.0/16"]
   }

   resource "azurerm_subnet" "workload" {
     name                 = "snet-workload"
     resource_group_name  = azurerm_resource_group.spoke.name
     virtual_network_name = azurerm_virtual_network.spoke.name
     address_prefixes     = ["10.1.0.0/24"]
   }

   resource "azurerm_subnet" "database" {
     name                 = "snet-database"
     resource_group_name  = azurerm_resource_group.spoke.name
     virtual_network_name = azurerm_virtual_network.spoke.name
     address_prefixes     = ["10.1.1.0/24"]
   }

   # VNet Peering
   resource "azurerm_virtual_network_peering" "hub_to_spoke" {
     name                      = "peer-hub-to-spoke"
     resource_group_name       = azurerm_resource_group.connectivity.name
     virtual_network_name      = azurerm_virtual_network.hub.name
     remote_virtual_network_id = azurerm_virtual_network.spoke.id
     allow_virtual_network_access = true
     allow_forwarded_traffic   = true
   }

   resource "azurerm_virtual_network_peering" "spoke_to_hub" {
     name                      = "peer-spoke-to-hub"
     resource_group_name       = azurerm_resource_group.spoke.name
     virtual_network_name      = azurerm_virtual_network.spoke.name
     remote_virtual_network_id = azurerm_virtual_network.hub.id
     allow_virtual_network_access = true
     allow_forwarded_traffic   = true
   }
   ```

3. Değişiklikleri kaydedin ve çıkın.

4. Terraform planını güncelleyin ve uygulayın:
   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

## Adım 6: Network Security Group Ekleme

1. `main.tf` dosyasını açın ve Spoke VNet yapılandırmasının altına aşağıdaki NSG yapılandırmasını ekleyin:
   ```bash
   nano main.tf
   ```

2. Aşağıdaki kodu ekleyin:
   ```hcl
   # Network Security Group
   resource "azurerm_network_security_group" "workload" {
     name                = "nsg-${var.root_id}-workload"
     location            = azurerm_resource_group.spoke.location
     resource_group_name = azurerm_resource_group.spoke.name
   }

   resource "azurerm_network_security_rule" "allow_rdp_from_hub" {
     name                        = "allow-rdp-from-hub"
     priority                    = 100
     direction                   = "Inbound"
     access                      = "Allow"
     protocol                    = "Tcp"
     source_port_range           = "*"
     destination_port_range      = "3389"
     source_address_prefix       = "10.0.0.0/16"
     destination_address_prefix  = "*"
     resource_group_name         = azurerm_resource_group.spoke.name
     network_security_group_name = azurerm_network_security_group.workload.name
   }

   resource "azurerm_subnet_network_security_group_association" "workload" {
     subnet_id                 = azurerm_subnet.workload.id
     network_security_group_id = azurerm_network_security_group.workload.id
   }
   ```

3. Değişiklikleri kaydedin ve çıkın.

4. Terraform planını güncelleyin ve uygulayın:
   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

## Adım 7: Azure Firewall Ekleme

1. `main.tf` dosyasını açın ve NSG yapılandırmasının altına aşağıdaki Firewall yapılandırmasını ekleyin:
   ```bash
   nano main.tf
   ```

2. Aşağıdaki kodu ekleyin:
   ```hcl
   # Azure Firewall
   resource "azurerm_public_ip" "firewall" {
     name                = "pip-${var.root_id}-firewall"
     location            = azurerm_resource_group.connectivity.location
     resource_group_name = azurerm_resource_group.connectivity.name
     allocation_method   = "Static"
     sku                 = "Standard"
   }

   resource "azurerm_firewall" "hub" {
     name                = "fw-${var.root_id}-hub"
     location            = azurerm_resource_group.connectivity.location
     resource_group_name = azurerm_resource_group.connectivity.name
     sku_name            = "AZFW_VNet"
     sku_tier            = "Standard"

     ip_configuration {
       name                 = "configuration"
       subnet_id            = azurerm_subnet.firewall.id
       public_ip_address_id = azurerm_public_ip.firewall.id
     }
   }

   resource "azurerm_firewall_network_rule_collection" "allow_spoke_to_spoke" {
     name                = "net-rule-collection-01"
     azure_firewall_name = azurerm_firewall.hub.name
     resource_group_name = azurerm_resource_group.connectivity.name
     priority            = 100
     action              = "Allow"

     rule {
       name                  = "allow-spoke-to-spoke"
       source_addresses      = ["10.1.0.0/16"]
       destination_addresses = ["10.1.0.0/16"]
       destination_ports     = ["*"]
       protocols             = ["Any"]
     }
   }

   resource "azurerm_firewall_application_rule_collection" "allow_web_traffic" {
     name                = "app-rule-collection-01"
     azure_firewall_name = azurerm_firewall.hub.name
     resource_group_name = azurerm_resource_group.connectivity.name
     priority            = 200
     action              = "Allow"

     rule {
       name             = "allow-web-traffic"
       source_addresses = ["10.1.0.0/16"]
       target_fqdns     = ["*.microsoft.com"]

       protocol {
         port = "443"
         type = "Https"
       }

       protocol {
         port = "80"
         type = "Http"
       }
     }
   }
   ```

3. Değişiklikleri kaydedin ve çıkın.

4. Terraform planını güncelleyin ve uygulayın:
   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

## Adım 8: Route Table Ekleme

1. `main.tf` dosyasını açın ve Firewall yapılandırmasının altına aşağıdaki Route Table yapılandırmasını ekleyin:
   ```bash
   nano main.tf
   ```

2. Aşağıdaki kodu ekleyin:
   ```hcl
   # Route Table
   resource "azurerm_route_table" "spoke_to_hub" {
     name                = "rt-${var.root_id}-spoke-to-hub"
     location            = azurerm_resource_group.connectivity.location
     resource_group_name = azurerm_resource_group.connectivity.name
   }

   resource "azurerm_route" "to_firewall" {
     name                   = "route-to-firewall"
     resource_group_name    = azurerm_resource_group.connectivity.name
     route_table_name       = azurerm_route_table.spoke_to_hub.name
     address_prefix         = "0.0.0.0/0"
     next_hop_type          = "VirtualAppliance"
     next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
   }

   resource "azurerm_subnet_route_table_association" "workload" {
     subnet_id      = azurerm_subnet.workload.id
     route_table_id = azurerm_route_table.spoke_to_hub.id
   }
   ```

3. Değişiklikleri kaydedin ve çıkın.

4. Terraform planını güncelleyin ve uygulayın:
   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

## Adım 9: Azure Portal'da Kaynakları İnceleme

1. Azure portalında [https://portal.azure.com](https://portal.azure.com) adresine gidin.
2. "Management groups" sayfasına gidin ve oluşturduğunuz management group hiyerarşisini inceleyin.
3. "Resource groups" sayfasına gidin ve oluşturduğunuz resource group'ları ve kaynakları inceleyin.
4. "Virtual networks" sayfasına gidin ve oluşturduğunuz hub ve spoke VNet'leri inceleyin.
5. "Network security groups" sayfasına gidin ve oluşturduğunuz NSG'yi inceleyin.
6. "Firewalls" sayfasına gidin ve oluşturduğunuz firewall'ı inceleyin.
7. "Route tables" sayfasına gidin ve oluşturduğunuz route table'ı inceleyin.

## Adım 10: Terraform State Yönetimi

1. Terraform state dosyasını inceleyin:
   ```bash
   terraform state list
   ```

2. Belirli bir kaynağın durumunu görüntüleyin:
   ```bash
   terraform state show azurerm_management_group.root
   ```

3. Uzak backend için Azure Storage Account yapılandırması (isteğe bağlı):
   ```bash
   # Storage Account oluşturun
   az group create --name rg-terraform-state --location westeurope
   az storage account create --name tfstate$RANDOM --resource-group rg-terraform-state --sku Standard_LRS --encryption-services blob
   az storage container create --name tfstate --account-name tfstate$RANDOM

   # Storage Account anahtarını alın
   ACCOUNT_KEY=$(az storage account keys list --resource-group rg-terraform-state --account-name tfstate$RANDOM --query '[0].value' -o tsv)

   # providers.tf dosyasını güncelleyin
   cat > providers.tf << EOF
   terraform {
     required_providers {
       azurerm = {
         source  = "hashicorp/azurerm"
         version = "~> 3.74.0"
       }
       azuread = {
         source  = "hashicorp/azuread"
         version = "~> 2.46.0"
       }
     }
     required_version = ">= 1.3.0"
     
     backend "azurerm" {
       resource_group_name  = "rg-terraform-state"
       storage_account_name = "tfstate$RANDOM"
       container_name       = "tfstate"
       key                  = "terraform.tfstate"
     }
   }

   provider "azurerm" {
     features {
       resource_group {
         prevent_deletion_if_contains_resources = false
       }
     }
   }

   provider "azuread" {}

   data "azurerm_client_config" "current" {}
   EOF

   # Terraform'u yeniden başlatın
   terraform init -migrate-state
   ```

## Özet

Bu lab çalışmasında aşağıdaki Azure landing zone bileşenlerini Terraform kullanarak oluşturdunuz ve yapılandırdınız:

- Management Groups hiyerarşisi
- Log Analytics Workspace
- Hub-Spoke ağ topolojisi
- Network Security Groups
- Azure Firewall
- Route Tables
- Policy tanımları ve atamaları

Bu yapılandırma, Azure landing zone'un temel bileşenlerini Infrastructure as Code yaklaşımıyla uygulamanızı sağlar.

## Temizlik (İsteğe Bağlı)

Lab çalışması tamamlandıktan sonra, oluşturduğunuz kaynakları temizlemek isterseniz:

1. Terraform ile tüm kaynakları kaldırın:
   ```bash
   terraform destroy
   ```

2. Onay istendiğinde "yes" yazın.

Not: Management group'ları silmek için önce içlerindeki tüm abonelikleri ve alt management group'ları taşımanız veya silmeniz gerekir. Terraform destroy komutu bunu otomatik olarak yapmaya çalışacaktır.
