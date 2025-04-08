# Lab 1: Azure Portal ve Temel Kaynaklar

Bu lab çalışmasında, Azure portalını kullanarak temel Azure kaynaklarını oluşturmayı öğreneceksiniz.

## Ön Koşullar

- Azure hesabı (ücretsiz deneme hesabı yeterlidir)
- Web tarayıcı (Chrome, Edge veya Firefox güncel sürüm)

## Adım 1: Azure Portalına Giriş

1. Web tarayıcınızı açın ve [https://portal.azure.com](https://portal.azure.com) adresine gidin.
2. Azure hesap bilgilerinizle oturum açın.
3. Azure portalının ana sayfasını inceleyin.

## Adım 2: Resource Group Oluşturma

1. Azure portalında sol üst köşedeki "Kaynak oluştur" (Create a resource) butonuna tıklayın.
2. Arama çubuğuna "Resource group" yazın ve çıkan sonuçtan "Resource group" seçeneğini seçin.
3. "Create" (Oluştur) butonuna tıklayın.
4. Aşağıdaki bilgileri doldurun:
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Resource group name: `rg-workshop-01`
   - Region: Size en yakın bölgeyi seçin (örn. "West Europe")
5. "Review + create" butonuna tıklayın.
6. Bilgileri kontrol edin ve "Create" butonuna tıklayarak resource group'u oluşturun.
7. Dağıtım tamamlandığında "Go to resource group" butonuna tıklayın.

## Adım 3: Storage Account Oluşturma

1. Oluşturduğunuz resource group içinde, üst menüden "Create" (Oluştur) butonuna tıklayın.
2. Arama çubuğuna "Storage account" yazın ve çıkan sonuçtan "Storage account" seçeneğini seçin.
3. "Create" butonuna tıklayın.
4. Aşağıdaki bilgileri doldurun:
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Resource group: `rg-workshop-01`
   - Storage account name: Benzersiz bir isim girin (örn. `stworkshop[adınız]`)
   - Region: Resource group ile aynı bölgeyi seçin
   - Performance: Standard
   - Redundancy: Locally-redundant storage (LRS)
5. "Review" butonuna tıklayın.
6. Bilgileri kontrol edin ve "Create" butonuna tıklayarak storage account'u oluşturun.
7. Dağıtım tamamlandığında "Go to resource" butonuna tıklayın.

## Adım 4: Blob Container Oluşturma

1. Storage account sayfasında, sol menüden "Containers" seçeneğini bulun ve tıklayın.
2. Üst menüden "+ Container" butonuna tıklayın.
3. Aşağıdaki bilgileri doldurun:
   - Name: `documents`
   - Public access level: Private (no anonymous access)
4. "Create" butonuna tıklayın.
5. Oluşturduğunuz container'a tıklayın.
6. "Upload" butonuna tıklayın.
7. Bilgisayarınızdan bir dosya seçin (herhangi bir metin dosyası olabilir).
8. "Upload" butonuna tıklayarak dosyayı yükleyin.

## Adım 5: Virtual Network Oluşturma

1. Azure portalında sol üst köşedeki "Kaynak oluştur" (Create a resource) butonuna tıklayın.
2. Arama çubuğuna "Virtual network" yazın ve çıkan sonuçtan "Virtual network" seçeneğini seçin.
3. "Create" butonuna tıklayın.
4. "Basics" sekmesinde aşağıdaki bilgileri doldurun:
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Resource group: `rg-workshop-01`
   - Name: `vnet-workshop-01`
   - Region: Resource group ile aynı bölgeyi seçin
5. "IP Addresses" sekmesine geçin.
6. IPv4 address space: `10.0.0.0/16` olarak bırakın.
7. Subnet bölümünde "default" subnet'i seçin ve düzenleyin:
   - Subnet name: `subnet-workshop-01`
   - Subnet address range: `10.0.0.0/24`
8. "Review + create" butonuna tıklayın.
9. Bilgileri kontrol edin ve "Create" butonuna tıklayarak virtual network'ü oluşturun.

## Adım 6: Network Security Group Oluşturma

1. Azure portalında sol üst köşedeki "Kaynak oluştur" (Create a resource) butonuna tıklayın.
2. Arama çubuğuna "Network security group" yazın ve çıkan sonuçtan "Network security group" seçeneğini seçin.
3. "Create" butonuna tıklayın.
4. Aşağıdaki bilgileri doldurun:
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Resource group: `rg-workshop-01`
   - Name: `nsg-workshop-01`
   - Region: Resource group ile aynı bölgeyi seçin
5. "Review + create" butonuna tıklayın.
6. Bilgileri kontrol edin ve "Create" butonuna tıklayarak NSG'yi oluşturun.
7. Dağıtım tamamlandığında "Go to resource" butonuna tıklayın.

## Adım 7: NSG Kuralı Ekleme

1. NSG sayfasında, sol menüden "Inbound security rules" seçeneğini bulun ve tıklayın.
2. "+ Add" butonuna tıklayın.
3. Aşağıdaki bilgileri doldurun:
   - Source: Any
   - Source port ranges: *
   - Destination: Any
   - Service: HTTP
   - Destination port ranges: 80
   - Protocol: TCP
   - Action: Allow
   - Priority: 100
   - Name: `Allow-HTTP`
4. "Add" butonuna tıklayın.
5. Aynı adımları tekrarlayarak HTTPS (port 443) için de bir kural ekleyin.

## Adım 8: NSG'yi Subnet'e Bağlama

1. NSG sayfasında, sol menüden "Subnets" seçeneğini bulun ve tıklayın.
2. "+ Associate" butonuna tıklayın.
3. Aşağıdaki bilgileri doldurun:
   - Virtual network: `vnet-workshop-01`
   - Subnet: `subnet-workshop-01`
4. "OK" butonuna tıklayın.

## Adım 9: Azure Monitor ve Log Analytics Workspace Oluşturma

1. Azure portalında sol üst köşedeki "Kaynak oluştur" (Create a resource) butonuna tıklayın.
2. Arama çubuğuna "Log Analytics workspace" yazın ve çıkan sonuçtan "Log Analytics workspace" seçeneğini seçin.
3. "Create" butonuna tıklayın.
4. Aşağıdaki bilgileri doldurun:
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Resource group: `rg-workshop-01`
   - Name: `law-workshop-01`
   - Region: Resource group ile aynı bölgeyi seçin
5. "Review + create" butonuna tıklayın.
6. Bilgileri kontrol edin ve "Create" butonuna tıklayarak workspace'i oluşturun.

## Adım 10: Kaynakları Etiketleme

1. `rg-workshop-01` resource group'una gidin.
2. Sol menüden "Tags" seçeneğini bulun ve tıklayın.
3. Aşağıdaki etiketleri ekleyin:
   - Name: `Environment` Value: `Training`
   - Name: `Project` Value: `AzureWorkshop`
4. "Apply" butonuna tıklayın.
5. Resource group içindeki tüm kaynakları seçin.
6. Üst menüden "Assign tags" butonuna tıklayın.
7. Aynı etiketleri kaynaklara da uygulayın.

## Adım 11: Azure Advisor İnceleme

1. Azure portalında sol menüden "Advisor" seçeneğini bulun ve tıklayın.
2. Advisor önerilerini inceleyin.
3. Maliyet optimizasyonu, güvenlik, güvenilirlik, operasyonel mükemmellik ve performans kategorilerindeki önerileri gözden geçirin.

## Adım 12: Maliyet Analizi

1. `rg-workshop-01` resource group'una gidin.
2. Sol menüden "Cost analysis" seçeneğini bulun ve tıklayın.
3. Maliyet analizini inceleyin ve farklı görünümleri keşfedin.
4. Bütçe oluşturma seçeneklerini inceleyin.

## Özet

Bu lab çalışmasında aşağıdaki Azure kaynaklarını oluşturdunuz ve yapılandırdınız:

- Resource Group
- Storage Account ve Blob Container
- Virtual Network ve Subnet
- Network Security Group ve Güvenlik Kuralları
- Log Analytics Workspace

Ayrıca, kaynakları etiketleme, Azure Advisor önerilerini inceleme ve maliyet analizi yapma konularında da deneyim kazandınız.

## Temizlik (İsteğe Bağlı)

Lab çalışması tamamlandıktan sonra, oluşturduğunuz kaynakları temizlemek isterseniz:

1. `rg-workshop-01` resource group'una gidin.
2. Üst menüden "Delete resource group" butonuna tıklayın.
3. Resource group adını yazarak silme işlemini onaylayın.
4. "Delete" butonuna tıklayın.

Bu işlem, resource group içindeki tüm kaynakları silecektir.
