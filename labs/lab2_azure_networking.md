# Lab 2: Azure Networking Yapılandırması

Bu lab çalışmasında, Azure networking kaynaklarını yapılandırmayı ve hub-spoke topolojisi oluşturmayı öğreneceksiniz.

## Ön Koşullar

- Azure hesabı (ücretsiz deneme hesabı yeterlidir)
- Web tarayıcı (Chrome, Edge veya Firefox güncel sürüm)
- Lab 1'in tamamlanmış olması

## Adım 1: Hub Virtual Network Oluşturma

1. Azure portalında sol üst köşedeki "Kaynak oluştur" (Create a resource) butonuna tıklayın.
2. Arama çubuğuna "Resource group" yazın ve çıkan sonuçtan "Resource group" seçeneğini seçin.
3. "Create" butonuna tıklayın.
4. Aşağıdaki bilgileri doldurun:
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Resource group name: `rg-workshop-hub`
   - Region: Size en yakın bölgeyi seçin (örn. "West Europe")
5. "Review + create" butonuna tıklayın ve "Create" butonuna tıklayarak resource group'u oluşturun.

6. Yeni bir resource group oluşturduktan sonra, "Kaynak oluştur" butonuna tıklayın.
7. Arama çubuğuna "Virtual network" yazın ve çıkan sonuçtan "Virtual network" seçeneğini seçin.
8. "Create" butonuna tıklayın.
9. "Basics" sekmesinde aşağıdaki bilgileri doldurun:
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Resource group: `rg-workshop-hub`
   - Name: `vnet-hub`
   - Region: Resource group ile aynı bölgeyi seçin
10. "IP Addresses" sekmesine geçin.
11. IPv4 address space: `10.0.0.0/16` olarak girin.
12. Subnet bölümünde "default" subnet'i silin ve aşağıdaki subnet'leri ekleyin:
    - Subnet name: `GatewaySubnet`
    - Subnet address range: `10.0.0.0/27`
    - Subnet name: `AzureFirewallSubnet`
    - Subnet address range: `10.0.1.0/26`
    - Subnet name: `snet-hub-management`
    - Subnet address range: `10.0.2.0/24`
13. "Review + create" butonuna tıklayın.
14. Bilgileri kontrol edin ve "Create" butonuna tıklayarak hub virtual network'ü oluşturun.

## Adım 2: Spoke Virtual Network Oluşturma

1. Azure portalında sol üst köşedeki "Kaynak oluştur" butonuna tıklayın.
2. Arama çubuğuna "Resource group" yazın ve çıkan sonuçtan "Resource group" seçeneğini seçin.
3. "Create" butonuna tıklayın.
4. Aşağıdaki bilgileri doldurun:
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Resource group name: `rg-workshop-spoke1`
   - Region: Hub ile aynı bölgeyi seçin
5. "Review + create" butonuna tıklayın ve "Create" butonuna tıklayarak resource group'u oluşturun.

6. Yeni bir resource group oluşturduktan sonra, "Kaynak oluştur" butonuna tıklayın.
7. Arama çubuğuna "Virtual network" yazın ve çıkan sonuçtan "Virtual network" seçeneğini seçin.
8. "Create" butonuna tıklayın.
9. "Basics" sekmesinde aşağıdaki bilgileri doldurun:
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Resource group: `rg-workshop-spoke1`
   - Name: `vnet-spoke1`
   - Region: Hub ile aynı bölgeyi seçin
10. "IP Addresses" sekmesine geçin.
11. IPv4 address space: `10.1.0.0/16` olarak girin.
12. Subnet bölümünde "default" subnet'i silin ve aşağıdaki subnet'leri ekleyin:
    - Subnet name: `snet-workload`
    - Subnet address range: `10.1.0.0/24`
    - Subnet name: `snet-database`
    - Subnet address range: `10.1.1.0/24`
13. "Review + create" butonuna tıklayın.
14. Bilgileri kontrol edin ve "Create" butonuna tıklayarak spoke virtual network'ü oluşturun.

## Adım 3: İkinci Spoke Virtual Network Oluşturma

1. Adım 2'yi tekrarlayarak ikinci bir spoke virtual network oluşturun:
   - Resource group name: `rg-workshop-spoke2`
   - Virtual network name: `vnet-spoke2`
   - Address space: `10.2.0.0/16`
   - Subnet name: `snet-workload`
   - Subnet address range: `10.2.0.0/24`
   - Subnet name: `snet-database`
   - Subnet address range: `10.2.1.0/24`

## Adım 4: Network Security Group Oluşturma ve Yapılandırma

1. Azure portalında sol üst köşedeki "Kaynak oluştur" butonuna tıklayın.
2. Arama çubuğuna "Network security group" yazın ve çıkan sonuçtan "Network security group" seçeneğini seçin.
3. "Create" butonuna tıklayın.
4. Aşağıdaki bilgileri doldurun:
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Resource group: `rg-workshop-spoke1`
   - Name: `nsg-spoke1-workload`
   - Region: Spoke1 ile aynı bölgeyi seçin
5. "Review + create" butonuna tıklayın ve "Create" butonuna tıklayarak NSG'yi oluşturun.

6. Dağıtım tamamlandığında "Go to resource" butonuna tıklayın.
7. Sol menüden "Inbound security rules" seçeneğini bulun ve tıklayın.
8. "+ Add" butonuna tıklayın.
9. Aşağıdaki bilgileri doldurun:
   - Source: IP Addresses
   - Source IP addresses/CIDR ranges: `10.0.0.0/16` (Hub VNet adresi)
   - Source port ranges: *
   - Destination: Any
   - Destination port ranges: 3389
   - Protocol: TCP
   - Action: Allow
   - Priority: 100
   - Name: `Allow-RDP-from-Hub`
10. "Add" butonuna tıklayın.

11. Sol menüden "Subnets" seçeneğini bulun ve tıklayın.
12. "+ Associate" butonuna tıklayın.
13. Aşağıdaki bilgileri doldurun:
    - Virtual network: `vnet-spoke1`
    - Subnet: `snet-workload`
14. "OK" butonuna tıklayın.

15. Adım 4'ü tekrarlayarak `rg-workshop-spoke2` resource group'unda `nsg-spoke2-workload` adında bir NSG oluşturun ve `vnet-spoke2` içindeki `snet-workload` subnet'ine bağlayın.

## Adım 5: Virtual Network Peering Yapılandırma

### Hub'dan Spoke1'e Peering

1. Azure portalında `vnet-hub` virtual network'üne gidin.
2. Sol menüden "Peerings" seçeneğini bulun ve tıklayın.
3. "+ Add" butonuna tıklayın.
4. Aşağıdaki bilgileri doldurun:
   - Peering link name (this virtual network to remote): `peer-hub-to-spoke1`
   - Peering link name (remote virtual network to this): `peer-spoke1-to-hub`
   - Virtual network deployment model: Resource manager
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Virtual network: `vnet-spoke1`
   - Traffic to remote virtual network: Allow
   - Traffic forwarded from remote virtual network: Allow
   - Virtual network gateway or Route Server: Use this virtual network's gateway
5. "Add" butonuna tıklayın.

### Hub'dan Spoke2'ye Peering

1. Azure portalında `vnet-hub` virtual network'üne gidin.
2. Sol menüden "Peerings" seçeneğini bulun ve tıklayın.
3. "+ Add" butonuna tıklayın.
4. Aşağıdaki bilgileri doldurun:
   - Peering link name (this virtual network to remote): `peer-hub-to-spoke2`
   - Peering link name (remote virtual network to this): `peer-spoke2-to-hub`
   - Virtual network deployment model: Resource manager
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Virtual network: `vnet-spoke2`
   - Traffic to remote virtual network: Allow
   - Traffic forwarded from remote virtual network: Allow
   - Virtual network gateway or Route Server: Use this virtual network's gateway
5. "Add" butonuna tıklayın.

## Adım 6: Azure Firewall Oluşturma

1. Azure portalında sol üst köşedeki "Kaynak oluştur" butonuna tıklayın.
2. Arama çubuğuna "Firewall" yazın ve çıkan sonuçtan "Firewall" seçeneğini seçin.
3. "Create" butonuna tıklayın.
4. "Basics" sekmesinde aşağıdaki bilgileri doldurun:
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Resource group: `rg-workshop-hub`
   - Name: `fw-hub`
   - Region: Hub ile aynı bölgeyi seçin
   - Firewall tier: Standard
   - Firewall management: Use Firewall rules (classic) to manage this firewall
   - Choose a virtual network: Use existing
   - Virtual network: `vnet-hub`
5. "Public IP address" bölümünde "Add new" seçeneğini seçin ve aşağıdaki bilgileri doldurun:
   - Name: `pip-fw-hub`
   - SKU: Standard
6. "Review + create" butonuna tıklayın.
7. Bilgileri kontrol edin ve "Create" butonuna tıklayarak firewall'ı oluşturun.

## Adım 7: Firewall Kuralları Oluşturma

1. Firewall dağıtımı tamamlandığında "Go to resource" butonuna tıklayın.
2. Sol menüden "Rules" seçeneğini bulun ve tıklayın.
3. "Network rule collection" sekmesine tıklayın.
4. "+ Add network rule collection" butonuna tıklayın.
5. Aşağıdaki bilgileri doldurun:
   - Name: `net-rule-collection-01`
   - Priority: 100
   - Action: Allow
6. Rules bölümünde aşağıdaki kuralı ekleyin:
   - Name: `allow-spoke-to-spoke`
   - Source type: IP Address
   - Source: `10.1.0.0/16,10.2.0.0/16` (Spoke VNet adresleri)
   - Protocol: Any
   - Destination Ports: *
   - Destination Type: IP Address
   - Destination: `10.1.0.0/16,10.2.0.0/16` (Spoke VNet adresleri)
7. "Add" butonuna tıklayın.

8. "Application rule collection" sekmesine tıklayın.
9. "+ Add application rule collection" butonuna tıklayın.
10. Aşağıdaki bilgileri doldurun:
    - Name: `app-rule-collection-01`
    - Priority: 200
    - Action: Allow
11. Rules bölümünde aşağıdaki kuralı ekleyin:
    - Name: `allow-web-traffic`
    - Source type: IP Address
    - Source: `10.1.0.0/16,10.2.0.0/16` (Spoke VNet adresleri)
    - Protocol: Http, Https
    - Target FQDNs: `*.microsoft.com`
12. "Add" butonuna tıklayın.

## Adım 8: Route Table Oluşturma ve Yapılandırma

1. Azure portalında sol üst köşedeki "Kaynak oluştur" butonuna tıklayın.
2. Arama çubuğuna "Route table" yazın ve çıkan sonuçtan "Route table" seçeneğini seçin.
3. "Create" butonuna tıklayın.
4. Aşağıdaki bilgileri doldurun:
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Resource group: `rg-workshop-hub`
   - Region: Hub ile aynı bölgeyi seçin
   - Name: `rt-spoke-to-hub`
   - Propagate gateway routes: No
5. "Review + create" butonuna tıklayın ve "Create" butonuna tıklayarak route table'ı oluşturun.

6. Dağıtım tamamlandığında "Go to resource" butonuna tıklayın.
7. Sol menüden "Routes" seçeneğini bulun ve tıklayın.
8. "+ Add" butonuna tıklayın.
9. Aşağıdaki bilgileri doldurun:
   - Route name: `route-to-firewall`
   - Address prefix: `0.0.0.0/0`
   - Next hop type: Virtual appliance
   - Next hop address: Firewall'ın özel IP adresini girin (Firewall sayfasından "Overview" sekmesinde bulabilirsiniz)
10. "Add" butonuna tıklayın.

11. Sol menüden "Subnets" seçeneğini bulun ve tıklayın.
12. "+ Associate" butonuna tıklayın.
13. Aşağıdaki bilgileri doldurun:
    - Virtual network: `vnet-spoke1`
    - Subnet: `snet-workload`
14. "OK" butonuna tıklayın.

15. "+ Associate" butonuna tekrar tıklayın.
16. Aşağıdaki bilgileri doldurun:
    - Virtual network: `vnet-spoke2`
    - Subnet: `snet-workload`
17. "OK" butonuna tıklayın.

## Adım 9: Sanal Makineler Oluşturma ve Test Etme

### Hub'da Jumpbox VM Oluşturma

1. Azure portalında sol üst köşedeki "Kaynak oluştur" butonuna tıklayın.
2. Arama çubuğuna "Virtual machine" yazın ve çıkan sonuçtan "Virtual machine" seçeneğini seçin.
3. "Create" butonuna tıklayın.
4. "Basics" sekmesinde aşağıdaki bilgileri doldurun:
   - Subscription: Kullanmak istediğiniz aboneliği seçin
   - Resource group: `rg-workshop-hub`
   - Virtual machine name: `vm-hub-jumpbox`
   - Region: Hub ile aynı bölgeyi seçin
   - Availability options: No infrastructure redundancy required
   - Image: Windows Server 2019 Datacenter
   - Size: Standard_B2s
   - Username: azureuser
   - Password: Güçlü bir parola belirleyin ve not alın
   - Public inbound ports: Allow selected ports
   - Select inbound ports: RDP (3389)
5. "Networking" sekmesine geçin.
6. Aşağıdaki bilgileri doldurun:
   - Virtual network: `vnet-hub`
   - Subnet: `snet-hub-management`
   - Public IP: Create new
   - NIC network security group: Basic
   - Public inbound ports: Allow selected ports
   - Select inbound ports: RDP (3389)
7. "Review + create" butonuna tıklayın.
8. Bilgileri kontrol edin ve "Create" butonuna tıklayarak VM'i oluşturun.

### Spoke1'de Workload VM Oluşturma

1. Adım 9'u tekrarlayarak Spoke1'de bir VM oluşturun:
   - Resource group: `rg-workshop-spoke1`
   - Virtual machine name: `vm-spoke1-workload`
   - Virtual network: `vnet-spoke1`
   - Subnet: `snet-workload`
   - Public IP: None

### Spoke2'de Workload VM Oluşturma

1. Adım 9'u tekrarlayarak Spoke2'de bir VM oluşturun:
   - Resource group: `rg-workshop-spoke2`
   - Virtual machine name: `vm-spoke2-workload`
   - Virtual network: `vnet-spoke2`
   - Subnet: `snet-workload`
   - Public IP: None

## Adım 10: Bağlantıyı Test Etme

1. Azure portalında `vm-hub-jumpbox` sanal makinesine gidin.
2. "Connect" butonuna tıklayın ve RDP ile bağlanın.
3. Sanal makineye bağlandıktan sonra, PowerShell açın.
4. Aşağıdaki komutları çalıştırarak Spoke1 ve Spoke2'deki VM'lere ping atın:
   ```powershell
   ping vm-spoke1-workload
   ping vm-spoke2-workload
   ```
5. Ayrıca, Spoke VM'lerinin internet bağlantısını test etmek için:
   ```powershell
   ping www.microsoft.com
   ```

## Özet

Bu lab çalışmasında aşağıdaki Azure networking kaynaklarını oluşturdunuz ve yapılandırdınız:

- Hub-Spoke topolojisi için Virtual Networks
- Network Security Groups
- Virtual Network Peering
- Azure Firewall
- Route Tables
- Sanal Makineler

Bu yapılandırma, gerçek dünya senaryolarında kullanılan hub-spoke ağ topolojisinin temel bir örneğidir.

## Temizlik (İsteğe Bağlı)

Lab çalışması tamamlandıktan sonra, oluşturduğunuz kaynakları temizlemek isterseniz:

1. `rg-workshop-hub`, `rg-workshop-spoke1` ve `rg-workshop-spoke2` resource group'larına gidin.
2. Her bir resource group için, üst menüden "Delete resource group" butonuna tıklayın.
3. Resource group adını yazarak silme işlemini onaylayın.
4. "Delete" butonuna tıklayın.

Bu işlem, resource group içindeki tüm kaynakları silecektir.
