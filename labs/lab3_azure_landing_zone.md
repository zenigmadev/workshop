# Lab 3: Azure Portal ile Landing Zone Kurulumu

Bu lab çalışmasında, Azure portalını kullanarak temel bir landing zone kurulumu gerçekleştireceksiniz. Management Groups oluşturacak, politikalar atayacak ve RBAC yapılandırması yapacaksınız.

## Ön Koşullar

- Azure hesabı (ücretsiz deneme hesabı yeterlidir)
- Web tarayıcı (Chrome, Edge veya Firefox güncel sürüm)
- Global Administrator veya User Access Administrator rolü
- Lab 1 ve Lab 2'nin tamamlanmış olması önerilir

## Adım 1: Management Groups Oluşturma

1. Azure portalında [https://portal.azure.com](https://portal.azure.com) adresine gidin.
2. Üst arama çubuğuna "management groups" yazın ve çıkan sonuçtan "Management groups" seçeneğini seçin.
3. "Start using management groups" butonuna tıklayın (eğer daha önce hiç management group oluşturmadıysanız).
4. "+ Create" butonuna tıklayın.
5. Aşağıdaki bilgileri doldurun:
   - Management group ID: `alz-workshop`
   - Management group display name: `Azure Landing Zone Workshop`
   - Management group details: Use tenant root group as the parent management group
6. "Submit" butonuna tıklayın.

7. Yeni oluşturduğunuz "Azure Landing Zone Workshop" management group'una tıklayın.
8. "+ Add management group" butonuna tıklayın.
9. Aşağıdaki bilgileri doldurun:
   - Management group ID: `platform`
   - Management group display name: `Platform`
10. "Submit" butonuna tıklayın.

11. Aynı şekilde aşağıdaki management group'ları da oluşturun:
    - Management group ID: `landingzones`
    - Management group display name: `Landing Zones`
    
    - Management group ID: `sandbox`
    - Management group display name: `Sandbox`
    
    - Management group ID: `decommissioned`
    - Management group display name: `Decommissioned`

12. "Platform" management group'una tıklayın.
13. "+ Add management group" butonuna tıklayın.
14. Aşağıdaki bilgileri doldurun:
    - Management group ID: `connectivity`
    - Management group display name: `Connectivity`
15. "Submit" butonuna tıklayın.

16. Aynı şekilde "Platform" altında aşağıdaki management group'ları da oluşturun:
    - Management group ID: `identity`
    - Management group display name: `Identity`
    
    - Management group ID: `management`
    - Management group display name: `Management`

17. "Landing Zones" management group'una tıklayın.
18. "+ Add management group" butonuna tıklayın.
19. Aşağıdaki bilgileri doldurun:
    - Management group ID: `corp`
    - Management group display name: `Corp`
20. "Submit" butonuna tıklayın.

21. Aynı şekilde "Landing Zones" altında aşağıdaki management group'u da oluşturun:
    - Management group ID: `online`
    - Management group display name: `Online`

## Adım 2: Abonelikleri Management Group'lara Taşıma

1. Azure portalında "Management groups" sayfasına gidin.
2. Mevcut aboneliğinizi uygun management group'a taşımak için, aboneliğinizin bulunduğu management group'a tıklayın.
3. Aboneliğinizin yanındaki üç noktaya (...) tıklayın ve "Move" seçeneğini seçin.
4. Hedef management group olarak "Corp" seçin.
5. "Save" butonuna tıklayın.

## Adım 3: Azure Policy Tanımları Oluşturma

1. Azure portalında üst arama çubuğuna "policy" yazın ve çıkan sonuçtan "Policy" seçeneğini seçin.
2. Sol menüden "Definitions" seçeneğini bulun ve tıklayın.
3. "+ Policy definition" butonuna tıklayın.
4. Aşağıdaki bilgileri doldurun:
   - Definition location: `Azure Landing Zone Workshop` management group
   - Name: `Require resource group tags`
   - Description: `This policy requires specified tags on resource groups.`
   - Category: Use existing > `Tags`
   - Policy rule: Aşağıdaki JSON'ı girin:
   ```json
   {
     "mode": "All",
     "parameters": {
       "tagName": {
         "type": "String",
         "metadata": {
           "displayName": "Tag Name",
           "description": "Name of the tag, such as 'environment'"
         }
       }
     },
     "policyRule": {
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
   }
   ```
5. "Save" butonuna tıklayın.

## Adım 4: Azure Policy Girişimleri (Initiatives) Oluşturma

1. Azure portalında "Policy" sayfasına gidin.
2. Sol menüden "Definitions" seçeneğini bulun ve tıklayın.
3. "+ Initiative definition" butonuna tıklayın.
4. Aşağıdaki bilgileri doldurun:
   - Definition location: `Azure Landing Zone Workshop` management group
   - Name: `Resource Tagging Initiative`
   - Description: `This initiative enforces tagging requirements across resources and resource groups.`
   - Category: Create new > `Tagging`
5. "Available Definitions" bölümünde, arama çubuğuna "tag" yazın.
6. Aşağıdaki politikaları seçin ve "Add" butonuna tıklayın:
   - Require resource group tags (az önce oluşturduğunuz politika)
   - Require a tag on resources
   - Inherit a tag from the resource group if missing
7. "Parameters" sekmesine geçin.
8. Her bir politika için "Tag Name" parametresini "Environment" olarak ayarlayın.
9. "Review + create" butonuna tıklayın.
10. "Create" butonuna tıklayın.

## Adım 5: Azure Policy Atama

1. Azure portalında "Policy" sayfasına gidin.
2. Sol menüden "Assignments" seçeneğini bulun ve tıklayın.
3. "+ Assign initiative" butonuna tıklayın.
4. "Basics" sekmesinde aşağıdaki bilgileri doldurun:
   - Scope: Management group > `Corp`
   - Exclusions: None
   - Policy definition: `Resource Tagging Initiative`
   - Assignment name: `Corp-Tagging-Initiative`
   - Description: `Enforces tagging requirements for Corp landing zone.`
   - Policy enforcement: Enabled
5. "Parameters" sekmesine geçin.
6. "Tag Name" parametresini "Environment" olarak bırakın.
7. "Remediation" sekmesine geçin.
8. "Create a remediation task" seçeneğini işaretleyin.
9. "Review + create" butonuna tıklayın.
10. "Create" butonuna tıklayın.

## Adım 6: Azure RBAC Rol Tanımları Oluşturma

1. Azure portalında üst arama çubuğuna "subscriptions" yazın ve çıkan sonuçtan "Subscriptions" seçeneğini seçin.
2. Aboneliğinize tıklayın.
3. Sol menüden "Access control (IAM)" seçeneğini bulun ve tıklayın.
4. "+ Add" butonuna tıklayın ve "Add custom role" seçeneğini seçin.
5. "Start from scratch" seçeneğini seçin ve "Next" butonuna tıklayın.
6. "Basics" sekmesinde aşağıdaki bilgileri doldurun:
   - Name: `Network Operations`
   - Description: `Can manage networking resources but cannot create or delete virtual networks.`
7. "Next" butonuna tıklayın.
8. "Permissions" sekmesinde "+ Add permissions" butonuna tıklayın.
9. Arama çubuğuna "network" yazın.
10. Aşağıdaki izinleri seçin:
    - Microsoft.Network/*/read
    - Microsoft.Network/networkSecurityGroups/*
    - Microsoft.Network/routeTables/*
    - Microsoft.Network/loadBalancers/*
    - Microsoft.Network/publicIPAddresses/*
    - Microsoft.Network/networkInterfaces/*
11. "Add" butonuna tıklayın.
12. "Next" butonuna tıklayın.
13. "Assignable scopes" sekmesinde, aboneliğinizin seçili olduğundan emin olun.
14. "Review + create" butonuna tıklayın.
15. "Create" butonuna tıklayın.

## Adım 7: Azure RBAC Rol Atama

1. Azure portalında "Subscriptions" sayfasına gidin.
2. Aboneliğinize tıklayın.
3. Sol menüden "Access control (IAM)" seçeneğini bulun ve tıklayın.
4. "+ Add" butonuna tıklayın ve "Add role assignment" seçeneğini seçin.
5. "Role" sekmesinde, arama çubuğuna "network operations" yazın ve oluşturduğunuz özel rolü seçin.
6. "Next" butonuna tıklayın.
7. "Members" sekmesinde, "+ Select members" butonuna tıklayın.
8. Kendi kullanıcı hesabınızı seçin.
9. "Select" butonuna tıklayın.
10. "Review + assign" butonuna tıklayın.
11. "Review + assign" butonuna tekrar tıklayın.

## Adım 8: Azure Blueprint Oluşturma

1. Azure portalında üst arama çubuğuna "blueprints" yazın ve çıkan sonuçtan "Blueprints" seçeneğini seçin.
2. "Create blueprint" butonuna tıklayın.
3. "Create blueprint" sayfasında, aşağıdaki bilgileri doldurun:
   - Blueprint name: `Corp Landing Zone Blueprint`
   - Blueprint description: `Standard configuration for Corp landing zone resources.`
   - Definition location: `Corp` management group
4. "Next : Artifacts" butonuna tıklayın.
5. "+ Add artifact" butonuna tıklayın.
6. "Artifact type" olarak "Resource group" seçin.
7. Aşağıdaki bilgileri doldurun:
   - Artifact display name: `Core Infrastructure Resource Group`
   - Resource group name: `rg-core-infrastructure`
   - Location: Size en yakın bölgeyi seçin
8. "Add" butonuna tıklayın.

9. "+ Add artifact" butonuna tekrar tıklayın.
10. "Artifact type" olarak "Azure Resource Manager template" seçin.
11. Aşağıdaki bilgileri doldurun:
    - Artifact display name: `Virtual Network`
    - Resource group: `rg-core-infrastructure`
    - Template location: Built-in template > `Virtual network with subnets`
12. "Add" butonuna tıklayın.

13. "+ Add artifact" butonuna tekrar tıklayın.
14. "Artifact type" olarak "Policy assignment" seçin.
15. Aşağıdaki bilgileri doldurun:
    - Artifact display name: `Require Resource Tags`
    - Policy definition: `Require a tag on resources`
    - Tag name: `Environment`
16. "Add" butonuna tıklayın.

17. "Save Draft" butonuna tıklayın.

## Adım 9: Azure Blueprint Yayınlama ve Atama

1. Azure portalında "Blueprints" sayfasına gidin.
2. "Blueprint definitions" sekmesinde, oluşturduğunuz `Corp Landing Zone Blueprint` blueprint'ine tıklayın.
3. "Publish blueprint" butonuna tıklayın.
4. "Version" alanına `1.0` yazın.
5. "Notes" alanına `Initial release` yazın.
6. "Publish" butonuna tıklayın.

7. "Assign blueprint" butonuna tıklayın.
8. "Basics" sekmesinde aşağıdaki bilgileri doldurun:
   - Subscription: Aboneliğinizi seçin
   - Assignment name: `Corp-LZ-Assignment`
   - Location: Size en yakın bölgeyi seçin
   - Blueprint definition version: `1.0`
   - Lock assignment: Don't lock
9. "Next : Artifacts" butonuna tıklayın.
10. "Virtual Network" artifact'ı için aşağıdaki parametreleri ayarlayın:
    - Virtual network name: `vnet-corp-01`
    - Virtual network address prefix: `10.10.0.0/16`
    - Subnet 1 name: `snet-workload`
    - Subnet 1 address prefix: `10.10.0.0/24`
    - Subnet 2 name: `snet-database`
    - Subnet 2 address prefix: `10.10.1.0/24`
11. "Require Resource Tags" artifact'ı için "Tag value" parametresini `Production` olarak ayarlayın.
12. "Review + create" butonuna tıklayın.
13. "Create" butonuna tıklayın.

## Adım 10: Azure Monitor ve Log Analytics Workspace Oluşturma

1. Azure portalında sol üst köşedeki "Kaynak oluştur" butonuna tıklayın.
2. Arama çubuğuna "Log Analytics workspace" yazın ve çıkan sonuçtan "Log Analytics workspace" seçeneğini seçin.
3. "Create" butonuna tıklayın.
4. Aşağıdaki bilgileri doldurun:
   - Subscription: Aboneliğinizi seçin
   - Resource group: `rg-management` (yeni oluşturun)
   - Name: `law-management-01`
   - Region: Size en yakın bölgeyi seçin
5. "Review + create" butonuna tıklayın.
6. "Create" butonuna tıklayın.

## Adım 11: Azure Security Center Yapılandırma

1. Azure portalında üst arama çubuğuna "security center" yazın ve çıkan sonuçtan "Security Center" seçeneğini seçin.
2. Sol menüden "Getting started" seçeneğini bulun ve tıklayın.
3. "Upgrade" butonuna tıklayın.
4. Aboneliğinizi seçin ve "Upgrade" butonuna tıklayın.
5. Sol menüden "Pricing & settings" seçeneğini bulun ve tıklayın.
6. Aboneliğinize tıklayın.
7. "Settings | Defender plans" sayfasında, "Servers" planını etkinleştirin.
8. "Save" butonuna tıklayın.

9. Sol menüden "Data collection" seçeneğini bulun ve tıklayın.
10. "Auto provisioning" bölümünde, "Log Analytics agent for Azure VMs" seçeneğini "On" olarak ayarlayın.
11. "Log Analytics workspace" bölümünde, daha önce oluşturduğunuz `law-management-01` workspace'i seçin.
12. "Save" butonuna tıklayın.

## Özet

Bu lab çalışmasında aşağıdaki Azure landing zone bileşenlerini oluşturdunuz ve yapılandırdınız:

- Management Groups hiyerarşisi
- Azure Policy tanımları ve atamaları
- RBAC rol tanımları ve atamaları
- Azure Blueprint
- Log Analytics Workspace
- Azure Security Center

Bu yapılandırma, Azure landing zone'un temel bileşenlerini içermektedir ve gerçek dünya senaryolarında daha kapsamlı bir şekilde uygulanabilir.

## Temizlik (İsteğe Bağlı)

Lab çalışması tamamlandıktan sonra, oluşturduğunuz kaynakları temizlemek isterseniz:

1. Azure portalında "Blueprints" sayfasına gidin ve blueprint atamasını silin.
2. "Resource groups" sayfasına gidin ve oluşturduğunuz resource group'ları silin.
3. "Policy" sayfasına gidin ve oluşturduğunuz policy atamalarını ve tanımlarını silin.
4. "Management groups" sayfasına gidin ve oluşturduğunuz management group'ları silin (en alt seviyeden başlayarak).

Not: Management group'ları silmek için önce içlerindeki tüm abonelikleri ve alt management group'ları taşımanız veya silmeniz gerekir.
