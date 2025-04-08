# Lab: Application Gateway ve Private AKS Cluster Entegrasyonu

Bu lab, Azure Application Gateway'in Private AKS Cluster ile entegrasyonunu adım adım ele almaktadır. Application Gateway Ingress Controller (AGIC) kullanarak güvenli ve ölçeklenebilir bir Kubernetes ortamı oluşturacaksınız.

## Gereksinimler

- Azure hesabı
- Azure CLI yüklü ve yapılandırılmış
- kubectl yüklü
- Helm yüklü (opsiyonel)

## Lab Hedefleri

Bu lab tamamlandığında şunları yapabileceksiniz:
- Private AKS Cluster oluşturma
- Azure Application Gateway kurulumu ve yapılandırması
- Application Gateway Ingress Controller (AGIC) kurulumu
- AGIC ile uygulamaları dağıtma ve yönetme

## Bölüm 1: Ortamı Hazırlama

### 1.1 Azure CLI ile Giriş Yapma

```bash
# Azure hesabınıza giriş yapın
az login

# Aboneliğinizi kontrol edin
az account show
```

### 1.2 Kaynak Grubu Oluşturma

```bash
# Kaynak grubu oluşturun
az group create --name private-aks-agic-rg --location eastus
```

### 1.3 Virtual Network ve Subnet Oluşturma

```bash
# Virtual Network oluşturun
az network vnet create \
  --name private-aks-vnet \
  --resource-group private-aks-agic-rg \
  --location eastus \
  --address-prefix 10.0.0.0/16

# AKS için Subnet oluşturun
az network vnet subnet create \
  --name aks-subnet \
  --resource-group private-aks-agic-rg \
  --vnet-name private-aks-vnet \
  --address-prefix 10.0.0.0/24

# Application Gateway için Subnet oluşturun
az network vnet subnet create \
  --name appgw-subnet \
  --resource-group private-aks-agic-rg \
  --vnet-name private-aks-vnet \
  --address-prefix 10.0.1.0/24
```

## Bölüm 2: Private AKS Cluster Oluşturma

### 2.1 Private AKS Cluster Oluşturma

```bash
# AKS Subnet ID'sini alın
AKS_SUBNET_ID=$(az network vnet subnet show \
  --name aks-subnet \
  --resource-group private-aks-agic-rg \
  --vnet-name private-aks-vnet \
  --query id -o tsv)

# Private AKS Cluster oluşturun
az aks create \
  --resource-group private-aks-agic-rg \
  --name private-aks-cluster \
  --location eastus \
  --node-count 2 \
  --node-vm-size Standard_DS2_v2 \
  --network-plugin azure \
  --vnet-subnet-id $AKS_SUBNET_ID \
  --enable-private-cluster \
  --enable-managed-identity \
  --generate-ssh-keys
```

### 2.2 AKS Kimlik Bilgilerini Alma

```bash
# AKS kimlik bilgilerini alın
az aks get-credentials \
  --resource-group private-aks-agic-rg \
  --name private-aks-cluster \
  --admin
```

### 2.3 Küme Bağlantısını Doğrulama

```bash
# Küme bağlantısını doğrulayın
kubectl get nodes
```

## Bölüm 3: Application Gateway Oluşturma

### 3.1 Application Gateway Oluşturma

```bash
# Application Gateway Subnet ID'sini alın
APPGW_SUBNET_ID=$(az network vnet subnet show \
  --name appgw-subnet \
  --resource-group private-aks-agic-rg \
  --vnet-name private-aks-vnet \
  --query id -o tsv)

# Public IP oluşturun
az network public-ip create \
  --resource-group private-aks-agic-rg \
  --name appgw-public-ip \
  --allocation-method Static \
  --sku Standard

# Application Gateway oluşturun
az network application-gateway create \
  --name private-aks-appgw \
  --resource-group private-aks-agic-rg \
  --location eastus \
  --sku Standard_v2 \
  --public-ip-address appgw-public-ip \
  --vnet-name private-aks-vnet \
  --subnet appgw-subnet \
  --min-capacity 1 \
  --max-capacity 3
```

## Bölüm 4: Application Gateway Ingress Controller (AGIC) Kurulumu

### 4.1 AKS Add-On Olarak AGIC Kurulumu

```bash
# Application Gateway ID'sini alın
APPGW_ID=$(az network application-gateway show \
  --name private-aks-appgw \
  --resource-group private-aks-agic-rg \
  --query id -o tsv)

# AGIC add-on'unu etkinleştirin
az aks enable-addons \
  --resource-group private-aks-agic-rg \
  --name private-aks-cluster \
  --addons ingress-appgw \
  --appgw-id $APPGW_ID
```

### 4.2 AGIC Kurulumunu Doğrulama

```bash
# AGIC pod'unu kontrol edin
kubectl get pods -n kube-system -l app=ingress-appgw
```

## Bölüm 5: Örnek Uygulama Dağıtımı

### 5.1 Örnek Uygulama için Namespace Oluşturma

```bash
# Namespace oluşturun
kubectl create namespace agic-demo
```

### 5.2 Örnek Uygulama Dağıtımı

Aşağıdaki YAML dosyasını `demo-app.yaml` olarak kaydedin:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: agic-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
      - name: demo-app
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
        env:
        - name: TITLE
          value: "AKS + Application Gateway Demo"
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app-service
  namespace: agic-demo
spec:
  selector:
    app: demo-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

Uygulamayı dağıtın:

```bash
kubectl apply -f demo-app.yaml
```

### 5.3 İkinci Örnek Uygulama Dağıtımı

Aşağıdaki YAML dosyasını `demo-app2.yaml` olarak kaydedin:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app2
  namespace: agic-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-app2
  template:
    metadata:
      labels:
        app: demo-app2
    spec:
      containers:
      - name: demo-app2
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
        env:
        - name: TITLE
          value: "AKS + Application Gateway Demo 2"
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app2-service
  namespace: agic-demo
spec:
  selector:
    app: demo-app2
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

İkinci uygulamayı dağıtın:

```bash
kubectl apply -f demo-app2.yaml
```

### 5.4 Ingress Kaynağı Oluşturma

Aşağıdaki YAML dosyasını `demo-ingress.yaml` olarak kaydedin:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  namespace: agic-demo
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
spec:
  rules:
  - http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: demo-app-service
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: demo-app2-service
            port:
              number: 80
```

Ingress kaynağını oluşturun:

```bash
kubectl apply -f demo-ingress.yaml
```

### 5.5 Ingress Durumunu Kontrol Etme

```bash
# Ingress durumunu kontrol edin
kubectl get ingress -n agic-demo
```

## Bölüm 6: TLS Terminasyonu Yapılandırma

### 6.1 Sertifika Oluşturma

```bash
# Özel anahtar oluşturun
openssl genrsa -out demo-tls.key 2048

# CSR oluşturun
openssl req -new -key demo-tls.key -out demo-tls.csr -subj "/CN=demo.example.com"

# Kendinden imzalı sertifika oluşturun
openssl x509 -req -days 365 -in demo-tls.csr -signkey demo-tls.key -out demo-tls.crt
```

### 6.2 Kubernetes Secret Oluşturma

```bash
# TLS Secret oluşturun
kubectl create secret tls demo-tls-secret \
  --namespace agic-demo \
  --key demo-tls.key \
  --cert demo-tls.crt
```

### 6.3 TLS Ingress Kaynağı Oluşturma

Aşağıdaki YAML dosyasını `demo-tls-ingress.yaml` olarak kaydedin:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-tls-ingress
  namespace: agic-demo
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - demo.example.com
    secretName: demo-tls-secret
  rules:
  - host: demo.example.com
    http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: demo-app-service
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: demo-app2-service
            port:
              number: 80
```

TLS Ingress kaynağını oluşturun:

```bash
kubectl apply -f demo-tls-ingress.yaml
```

## Bölüm 7: Özel Anotasyonlar ile Gelişmiş Yapılandırma

### 7.1 Özel Anotasyonlar ile Ingress Oluşturma

Aşağıdaki YAML dosyasını `advanced-ingress.yaml` olarak kaydedin:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: advanced-ingress
  namespace: agic-demo
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/ssl-redirect: "true"
    appgw.ingress.kubernetes.io/connection-draining: "true"
    appgw.ingress.kubernetes.io/connection-draining-timeout: "30"
    appgw.ingress.kubernetes.io/cookie-based-affinity: "true"
    appgw.ingress.kubernetes.io/health-probe-path: "/healthz"
    appgw.ingress.kubernetes.io/health-probe-status-codes: "200-399"
spec:
  tls:
  - hosts:
    - demo.example.com
    secretName: demo-tls-secret
  rules:
  - host: demo.example.com
    http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: demo-app-service
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: demo-app2-service
            port:
              number: 80
```

Gelişmiş Ingress kaynağını oluşturun:

```bash
kubectl apply -f advanced-ingress.yaml
```

### 7.2 Private IP Kullanımı

Aşağıdaki YAML dosyasını `private-ip-ingress.yaml` olarak kaydedin:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: private-ip-ingress
  namespace: agic-demo
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/use-private-ip: "true"
spec:
  rules:
  - http:
      paths:
      - path: /private
        pathType: Prefix
        backend:
          service:
            name: demo-app-service
            port:
              number: 80
```

Private IP Ingress kaynağını oluşturun:

```bash
kubectl apply -f private-ip-ingress.yaml
```

## Bölüm 8: İzleme ve Sorun Giderme

### 8.1 AGIC Günlüklerini Kontrol Etme

```bash
# AGIC pod adını alın
AGIC_POD=$(kubectl get pods -n kube-system -l app=ingress-appgw -o jsonpath='{.items[0].metadata.name}')

# AGIC günlüklerini görüntüleyin
kubectl logs -n kube-system $AGIC_POD
```

### 8.2 Application Gateway Durumunu Kontrol Etme

```bash
# Application Gateway durumunu kontrol edin
az network application-gateway show \
  --name private-aks-appgw \
  --resource-group private-aks-agic-rg \
  --query "operationalState" -o tsv
```

### 8.3 Application Gateway Yapılandırmasını Kontrol Etme

```bash
# HTTP ayarlarını kontrol edin
az network application-gateway http-settings list \
  --gateway-name private-aks-appgw \
  --resource-group private-aks-agic-rg \
  --query "[].{Name:name, Port:port, Protocol:protocol}" -o table

# Backend havuzlarını kontrol edin
az network application-gateway address-pool list \
  --gateway-name private-aks-appgw \
  --resource-group private-aks-agic-rg \
  --query "[].{Name:name, Backends:backendAddresses}" -o table

# Yönlendirme kurallarını kontrol edin
az network application-gateway rule list \
  --gateway-name private-aks-appgw \
  --resource-group private-aks-agic-rg \
  --query "[].{Name:name, Priority:priority}" -o table
```

### 8.4 Azure Monitor ile İzleme

```bash
# AKS için Azure Monitor'ü etkinleştirin (zaten etkinleştirilmişse atlayın)
az aks enable-addons \
  --resource-group private-aks-agic-rg \
  --name private-aks-cluster \
  --addons monitoring
```

Azure portalında, Application Gateway ve AKS kümesine gidin ve "Insights" bölümünü açarak izleme verilerini görüntüleyin.

## Bölüm 9: Temizlik

```bash
# Namespace'i silin
kubectl delete namespace agic-demo

# AGIC add-on'unu devre dışı bırakın
az aks disable-addons \
  --resource-group private-aks-agic-rg \
  --name private-aks-cluster \
  --addons ingress-appgw

# Application Gateway'i silin
az network application-gateway delete \
  --name private-aks-appgw \
  --resource-group private-aks-agic-rg

# Public IP'yi silin
az network public-ip delete \
  --name appgw-public-ip \
  --resource-group private-aks-agic-rg

# AKS kümesini silin
az aks delete \
  --resource-group private-aks-agic-rg \
  --name private-aks-cluster \
  --yes

# Virtual Network'ü silin
az network vnet delete \
  --name private-aks-vnet \
  --resource-group private-aks-agic-rg

# Kaynak grubunu silin
az group delete \
  --name private-aks-agic-rg \
  --yes
```

## Özet

Bu lab'da şunları öğrendiniz:
- Private AKS Cluster oluşturma
- Azure Application Gateway kurulumu ve yapılandırması
- Application Gateway Ingress Controller (AGIC) kurulumu
- AGIC ile uygulamaları dağıtma ve yönetme
- TLS terminasyonu yapılandırma
- Özel anotasyonlar ile gelişmiş yapılandırma
- İzleme ve sorun giderme

Bu bilgiler, gerçek dünya senaryolarında Application Gateway ve Private AKS Cluster entegrasyonu projelerinde size yardımcı olacaktır.
