# Lab: IBM Cloud Kubernetes'ten Azure Kubernetes Service'e Geçiş

Bu lab, IBM Cloud Kubernetes Service'ten Azure Kubernetes Service (AKS)'e geçiş sürecini adım adım ele almaktadır. Örnek bir uygulama kullanarak, geçiş stratejilerini, veri taşıma yöntemlerini ve geçiş sonrası doğrulama adımlarını uygulayacaksınız.

## Gereksinimler

- Azure hesabı
- Azure CLI yüklü ve yapılandırılmış
- kubectl yüklü
- Helm yüklü (opsiyonel)
- Velero CLI yüklü (opsiyonel)

## Lab Hedefleri

Bu lab tamamlandığında şunları yapabileceksiniz:
- IBM Cloud Kubernetes ve AKS arasındaki farkları anlama
- Geçiş stratejilerini değerlendirme ve seçme
- Örnek bir uygulamayı IBM Cloud'dan AKS'ye taşıma
- Geçiş sonrası doğrulama ve test yapma

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
az group create --name aks-migration-rg --location eastus
```

### 1.3 AKS Kümesi Oluşturma

```bash
# AKS kümesi oluşturun
az aks create \
    --resource-group aks-migration-rg \
    --name aks-migration-cluster \
    --node-count 3 \
    --enable-addons monitoring \
    --generate-ssh-keys
```

### 1.4 AKS Kimlik Bilgilerini Alma

```bash
# AKS kimlik bilgilerini alın
az aks get-credentials \
    --resource-group aks-migration-rg \
    --name aks-migration-cluster
```

### 1.5 Küme Bağlantısını Doğrulama

```bash
# Küme bağlantısını doğrulayın
kubectl get nodes
```

## Bölüm 2: Örnek Uygulama Dağıtımı

### 2.1 Örnek Uygulama için Namespace Oluşturma

```bash
# Namespace oluşturun
kubectl create namespace migration-demo
```

### 2.2 Örnek Uygulama Dağıtımı

Aşağıdaki YAML dosyasını `sample-app.yaml` olarak kaydedin:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: migration-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: sample-app
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-service
  namespace: migration-demo
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

Uygulamayı dağıtın:

```bash
kubectl apply -f sample-app.yaml
```

### 2.3 Uygulama Durumunu Kontrol Etme

```bash
# Deployment durumunu kontrol edin
kubectl get deployments -n migration-demo

# Pod'ları kontrol edin
kubectl get pods -n migration-demo

# Servisi kontrol edin
kubectl get services -n migration-demo
```

## Bölüm 3: Geçiş Stratejileri

Bu bölümde, üç farklı geçiş stratejisini inceleyeceğiz:
1. Lift and Shift (Doğrudan Taşıma)
2. Yedekleme ve Geri Yükleme
3. Kademeli Geçiş

### 3.1 Lift and Shift (Doğrudan Taşıma)

#### 3.1.1 Kaynak Tanımlarını Dışa Aktarma

```bash
# Deployment, Service, ConfigMap ve Secret kaynaklarını dışa aktarın
kubectl get deployment,service,configmap,secret -n migration-demo -o yaml > resources.yaml
```

#### 3.1.2 Kaynak Tanımlarını Düzenleme

`resources.yaml` dosyasını bir metin editöründe açın ve aşağıdaki değişiklikleri yapın:
- Gereksiz metadata alanlarını kaldırın (resourceVersion, uid, creationTimestamp vb.)
- IBM Cloud'a özgü anotasyonları ve etiketleri kaldırın
- Gerekirse, depolama sınıfı referanslarını güncelleyin

#### 3.1.3 AKS'ye Uygulama

```bash
# Düzenlenmiş kaynakları AKS'ye uygulayın
kubectl apply -f resources.yaml
```

### 3.2 Yedekleme ve Geri Yükleme (Velero ile)

#### 3.2.1 Velero Kurulumu

```bash
# Azure için gerekli kimlik bilgilerini oluşturun
AZURE_BACKUP_RESOURCE_GROUP=velero-backups
AZURE_STORAGE_ACCOUNT_NAME=velerobackup$RANDOM
BLOB_CONTAINER=velero

# Kaynak grubu oluşturun
az group create -n $AZURE_BACKUP_RESOURCE_GROUP --location eastus

# Depolama hesabı oluşturun
az storage account create \
    --name $AZURE_STORAGE_ACCOUNT_NAME \
    --resource-group $AZURE_BACKUP_RESOURCE_GROUP \
    --sku Standard_LRS \
    --encryption-services blob \
    --https-only true \
    --kind BlobStorage \
    --access-tier Hot

# Blob container oluşturun
az storage container create \
    --name $BLOB_CONTAINER \
    --public-access off \
    --account-name $AZURE_STORAGE_ACCOUNT_NAME

# Depolama hesabı anahtarını alın
AZURE_STORAGE_ACCOUNT_ACCESS_KEY=$(az storage account keys list \
    --account-name $AZURE_STORAGE_ACCOUNT_NAME \
    --resource-group $AZURE_BACKUP_RESOURCE_GROUP \
    --query "[0].value" \
    --output tsv)

# credentials-velero dosyasını oluşturun
cat << EOF > ./credentials-velero
AZURE_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
AZURE_TENANT_ID=$(az account show --query tenantId --output tsv)
AZURE_CLIENT_ID=
AZURE_CLIENT_SECRET=
AZURE_RESOURCE_GROUP=${AZURE_BACKUP_RESOURCE_GROUP}
AZURE_STORAGE_ACCOUNT_ACCESS_KEY=${AZURE_STORAGE_ACCOUNT_ACCESS_KEY}
AZURE_CLOUD_NAME=AzurePublicCloud
EOF

# Velero'yu Helm ile kurun
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update

helm install velero vmware-tanzu/velero \
    --namespace velero \
    --create-namespace \
    --set-file credentials.secretContents.cloud=./credentials-velero \
    --set configuration.provider=azure \
    --set configuration.backupStorageLocation.bucket=$BLOB_CONTAINER \
    --set configuration.backupStorageLocation.config.resourceGroup=$AZURE_BACKUP_RESOURCE_GROUP \
    --set configuration.backupStorageLocation.config.storageAccount=$AZURE_STORAGE_ACCOUNT_NAME \
    --set configuration.backupStorageLocation.config.subscriptionId=$(az account show --query id --output tsv) \
    --set initContainers[0].name=velero-plugin-for-microsoft-azure \
    --set initContainers[0].image=velero/velero-plugin-for-microsoft-azure:v1.4.0 \
    --set initContainers[0].volumeMounts[0].mountPath=/target \
    --set initContainers[0].volumeMounts[0].name=plugins
```

#### 3.2.2 Yedekleme Oluşturma

```bash
# Namespace'i yedekleyin
velero backup create migration-demo-backup --include-namespaces migration-demo
```

#### 3.2.3 Yedekleme Durumunu Kontrol Etme

```bash
# Yedekleme durumunu kontrol edin
velero backup describe migration-demo-backup
```

#### 3.2.4 Geri Yükleme

```bash
# Yedekten geri yükleyin
velero restore create --from-backup migration-demo-backup
```

#### 3.2.5 Geri Yükleme Durumunu Kontrol Etme

```bash
# Geri yükleme durumunu kontrol edin
velero restore describe migration-demo-backup

# Kaynakları kontrol edin
kubectl get all -n migration-demo
```

### 3.3 Kademeli Geçiş

Kademeli geçiş için, Azure Traffic Manager veya Azure Front Door kullanarak trafiği yönlendirebilirsiniz.

#### 3.3.1 Azure Traffic Manager Profili Oluşturma

```bash
# Traffic Manager profili oluşturun
az network traffic-manager profile create \
    --name migration-tm-profile \
    --resource-group aks-migration-rg \
    --routing-method weighted \
    --unique-dns-name migration-demo-tm

# IBM Cloud endpoint'i ekleyin (varsayımsal)
az network traffic-manager endpoint create \
    --name ibm-cloud-endpoint \
    --profile-name migration-tm-profile \
    --resource-group aks-migration-rg \
    --type externalEndpoints \
    --endpoint-status enabled \
    --target ibm-app-endpoint.example.com \
    --weight 100

# AKS endpoint'i alın
AKS_ENDPOINT_IP=$(kubectl get service sample-app-service -n migration-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# AKS endpoint'i ekleyin
az network traffic-manager endpoint create \
    --name aks-endpoint \
    --profile-name migration-tm-profile \
    --resource-group aks-migration-rg \
    --type externalEndpoints \
    --endpoint-status enabled \
    --target $AKS_ENDPOINT_IP \
    --weight 0
```

#### 3.3.2 Trafiği Kademeli Olarak Kaydırma

```bash
# AKS endpoint ağırlığını artırın
az network traffic-manager endpoint update \
    --name aks-endpoint \
    --profile-name migration-tm-profile \
    --resource-group aks-migration-rg \
    --weight 50

# IBM Cloud endpoint ağırlığını azaltın
az network traffic-manager endpoint update \
    --name ibm-cloud-endpoint \
    --profile-name migration-tm-profile \
    --resource-group aks-migration-rg \
    --weight 50

# Tüm trafiği AKS'ye yönlendirin
az network traffic-manager endpoint update \
    --name aks-endpoint \
    --profile-name migration-tm-profile \
    --resource-group aks-migration-rg \
    --weight 100

az network traffic-manager endpoint update \
    --name ibm-cloud-endpoint \
    --profile-name migration-tm-profile \
    --resource-group aks-migration-rg \
    --weight 0
```

## Bölüm 4: Veri Taşıma Stratejileri

### 4.1 Azure Files ile Kalıcı Depolama

#### 4.1.1 Azure Files Depolama Hesabı Oluşturma

```bash
# Depolama hesabı oluşturun
az storage account create \
    --name aksmigrationsa$RANDOM \
    --resource-group aks-migration-rg \
    --location eastus \
    --sku Standard_LRS \
    --kind StorageV2

# Depolama hesabı adını alın
STORAGE_ACCOUNT_NAME=$(az storage account list \
    --resource-group aks-migration-rg \
    --query "[?contains(name, 'aksmigrationsa')].name" \
    --output tsv)

# Dosya paylaşımı oluşturun
az storage share create \
    --name migration-data \
    --account-name $STORAGE_ACCOUNT_NAME

# Depolama hesabı anahtarını alın
STORAGE_KEY=$(az storage account keys list \
    --resource-group aks-migration-rg \
    --account-name $STORAGE_ACCOUNT_NAME \
    --query "[0].value" \
    --output tsv)
```

#### 4.1.2 Kubernetes Secret Oluşturma

```bash
# Kubernetes Secret oluşturun
kubectl create secret generic azure-files-secret \
    --from-literal=azurestorageaccountname=$STORAGE_ACCOUNT_NAME \
    --from-literal=azurestorageaccountkey=$STORAGE_KEY \
    --namespace migration-demo
```

#### 4.1.3 PersistentVolume ve PersistentVolumeClaim Oluşturma

Aşağıdaki YAML dosyasını `azure-files-pv.yaml` olarak kaydedin:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: azure-files-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: azure-file
  azureFile:
    secretName: azure-files-secret
    shareName: migration-data
    readOnly: false
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-files-pvc
  namespace: migration-demo
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: azure-file
  resources:
    requests:
      storage: 5Gi
```

PV ve PVC oluşturun:

```bash
kubectl apply -f azure-files-pv.yaml
```

#### 4.1.4 Depolama Kullanımı için Deployment Güncelleme

Aşağıdaki YAML dosyasını `stateful-app.yaml` olarak kaydedin:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stateful-app
  namespace: migration-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: stateful-app
  template:
    metadata:
      labels:
        app: stateful-app
    spec:
      containers:
      - name: stateful-app
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: azure-files-storage
          mountPath: /usr/share/nginx/html
      volumes:
      - name: azure-files-storage
        persistentVolumeClaim:
          claimName: azure-files-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: stateful-app-service
  namespace: migration-demo
spec:
  selector:
    app: stateful-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

Stateful uygulamayı dağıtın:

```bash
kubectl apply -f stateful-app.yaml
```

### 4.2 Azure Managed Disks ile Kalıcı Depolama

#### 4.2.1 StorageClass Oluşturma

Aşağıdaki YAML dosyasını `managed-disk-sc.yaml` olarak kaydedin:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-premium
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
```

StorageClass oluşturun:

```bash
kubectl apply -f managed-disk-sc.yaml
```

#### 4.2.2 PersistentVolumeClaim Oluşturma

Aşağıdaki YAML dosyasını `managed-disk-pvc.yaml` olarak kaydedin:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: managed-disk-pvc
  namespace: migration-demo
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-premium
  resources:
    requests:
      storage: 5Gi
```

PVC oluşturun:

```bash
kubectl apply -f managed-disk-pvc.yaml
```

#### 4.2.3 Managed Disk Kullanımı için Deployment Oluşturma

Aşağıdaki YAML dosyasını `disk-app.yaml` olarak kaydedin:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: disk-app
  namespace: migration-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: disk-app
  template:
    metadata:
      labels:
        app: disk-app
    spec:
      containers:
      - name: disk-app
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: managed-disk-storage
          mountPath: /usr/share/nginx/html
      volumes:
      - name: managed-disk-storage
        persistentVolumeClaim:
          claimName: managed-disk-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: disk-app-service
  namespace: migration-demo
spec:
  selector:
    app: disk-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

Disk uygulamasını dağıtın:

```bash
kubectl apply -f disk-app.yaml
```

## Bölüm 5: Geçiş Sonrası Doğrulama

### 5.1 Uygulama Sağlığını Kontrol Etme

```bash
# Deployment durumunu kontrol edin
kubectl get deployments -n migration-demo

# Pod'ları kontrol edin
kubectl get pods -n migration-demo

# Servisleri kontrol edin
kubectl get services -n migration-demo

# Pod günlüklerini kontrol edin
kubectl logs -n migration-demo -l app=sample-app
```

### 5.2 Kaynak Kullanımını İzleme

```bash
# Pod kaynak kullanımını kontrol edin
kubectl top pods -n migration-demo

# Düğüm kaynak kullanımını kontrol edin
kubectl top nodes
```

### 5.3 Ağ Bağlantısını Test Etme

```bash
# Servis IP adreslerini alın
SAMPLE_APP_IP=$(kubectl get service sample-app-service -n migration-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
STATEFUL_APP_IP=$(kubectl get service stateful-app-service -n migration-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
DISK_APP_IP=$(kubectl get service disk-app-service -n migration-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Servislere erişimi test edin
curl http://$SAMPLE_APP_IP
curl http://$STATEFUL_APP_IP
curl http://$DISK_APP_IP
```

### 5.4 Azure Monitor ile İzleme

```bash
# AKS için Azure Monitor'ü etkinleştirin (zaten etkinleştirilmişse atlayın)
az aks enable-addons \
    --resource-group aks-migration-rg \
    --name aks-migration-cluster \
    --addons monitoring
```

Azure portalında, AKS kümesine gidin ve "Insights" bölümünü açarak izleme verilerini görüntüleyin.

## Bölüm 6: Temizlik

```bash
# Namespace'i silin
kubectl delete namespace migration-demo

# Traffic Manager profilini silin
az network traffic-manager profile delete \
    --name migration-tm-profile \
    --resource-group aks-migration-rg

# Depolama hesabını silin
az storage account delete \
    --name $STORAGE_ACCOUNT_NAME \
    --resource-group aks-migration-rg \
    --yes

# Velero'yu kaldırın
helm uninstall velero -n velero
kubectl delete namespace velero

# Velero yedekleme kaynak grubunu silin
az group delete \
    --name $AZURE_BACKUP_RESOURCE_GROUP \
    --yes

# AKS kümesini silin
az aks delete \
    --resource-group aks-migration-rg \
    --name aks-migration-cluster \
    --yes

# Kaynak grubunu silin
az group delete \
    --name aks-migration-rg \
    --yes
```

## Özet

Bu lab'da şunları öğrendiniz:
- IBM Cloud Kubernetes'ten AKS'ye geçiş stratejilerini uygulama
- Lift and Shift, Yedekleme ve Geri Yükleme, ve Kademeli Geçiş yaklaşımlarını kullanma
- Azure Files ve Azure Managed Disks ile kalıcı depolama yapılandırma
- Geçiş sonrası doğrulama ve izleme yapma

Bu bilgiler, gerçek dünya senaryolarında IBM Cloud Kubernetes'ten AKS'ye geçiş projelerinde size yardımcı olacaktır.
