# Terraform için Azure DevOps Pipeline Dokümantasyonu

Bu doküman, Terraform altyapı kodunuz için oluşturulan Azure DevOps pipeline'ının detaylı açıklamasını içermektedir. Pipeline, Terraform kodunuzu doğrulama, planlama ve uygulama aşamalarını otomatikleştirerek, altyapı değişikliklerinin güvenli ve tutarlı bir şekilde dağıtılmasını sağlar.

## İçindekiler

1. [Genel Bakış](#genel-bakış)
2. [Ön Koşullar](#ön-koşullar)
3. [Pipeline Yapısı](#pipeline-yapısı)
4. [Aşamalar ve İş Akışları](#aşamalar-ve-iş-akışları)
5. [Ortam Konfigürasyonları](#ortam-konfigürasyonları)
6. [Güvenlik ve Kimlik Doğrulama](#güvenlik-ve-kimlik-doğrulama)
7. [Durum Yönetimi](#durum-yönetimi)
8. [Onay Mekanizmaları](#onay-mekanizmaları)
9. [Hata Ayıklama ve Sorun Giderme](#hata-ayıklama-ve-sorun-giderme)
10. [En İyi Uygulamalar](#en-iyi-uygulamalar)

## Genel Bakış

Bu Azure DevOps pipeline, Terraform altyapı kodunuzu geliştirme, test ve üretim ortamlarına güvenli bir şekilde dağıtmak için tasarlanmıştır. Pipeline, aşağıdaki temel özelliklere sahiptir:

- Çoklu ortam desteği (Dev, Test, Prod)
- Otomatik doğrulama ve kod kalitesi kontrolleri
- Ortamlar arası aşamalı dağıtım
- Güvenli kimlik bilgisi yönetimi
- Merkezi durum dosyası yönetimi
- Onay tabanlı üretim dağıtımları

## Ön Koşullar

Pipeline'ı kullanmadan önce aşağıdaki gereksinimlerin karşılanması gerekmektedir:

1. **Azure DevOps Organizasyonu ve Projesi**: Pipeline'ı çalıştırmak için bir Azure DevOps organizasyonu ve projesi.

2. **Service Principal**: Azure kaynaklarına erişim için bir Azure Service Principal.

3. **Değişken Grubu**: Azure DevOps'ta `terraform-credentials` adında bir değişken grubu oluşturulmalı ve aşağıdaki değişkenleri içermelidir:
   - `ARM_CLIENT_ID`: Azure Service Principal Client ID
   - `ARM_CLIENT_SECRET`: Azure Service Principal Client Secret
   - `ARM_SUBSCRIPTION_ID`: Azure Subscription ID
   - `ARM_TENANT_ID`: Azure Tenant ID

4. **Terraform Dizin Yapısı**: Aşağıdaki yapıya uygun bir Terraform kod organizasyonu:
   ```
   terraform/
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
   ├── providers.tf
   ├── environments/
   │   ├── dev/
   │   │   └── terraform.tfvars
   │   ├── test/
   │   │   └── terraform.tfvars
   │   └── prod/
   │       └── terraform.tfvars
   └── modules/
       └── ...
   ```

5. **Azure DevOps Ortamları**: Pipeline'da kullanılan her ortam için Azure DevOps'ta ortam tanımları:
   - Development
   - Test
   - Production

## Pipeline Yapısı

Pipeline, aşağıdaki ana bileşenlerden oluşmaktadır:

1. **Tetikleyiciler (Triggers)**: Pipeline, `main` dalına yapılan değişikliklerde ve `terraform/` dizinindeki dosyalarda değişiklik olduğunda otomatik olarak çalışır.

2. **Değişkenler (Variables)**: Pipeline, Terraform sürümü, çalışma dizini ve backend yapılandırması için değişkenler içerir.

3. **Aşamalar (Stages)**: Pipeline, aşağıdaki aşamalardan oluşur:
   - Validate: Terraform kodunun doğrulanması
   - Plan (Dev/Test/Prod): Her ortam için altyapı değişikliklerinin planlanması
   - Apply (Dev/Test/Prod): Her ortam için altyapı değişikliklerinin uygulanması

## Aşamalar ve İş Akışları

### Validate Aşaması

Bu aşama, Terraform kodunun sözdizimi ve yapılandırma doğruluğunu kontrol eder:

1. **Terraform Kurulumu**: Belirtilen Terraform sürümünü yükler.
2. **Terraform Init**: Backend yapılandırması olmadan Terraform'u başlatır.
3. **Terraform Format**: Kod formatını kontrol eder.
4. **Terraform Validate**: Terraform yapılandırmasının geçerliliğini doğrular.

### Plan Aşaması (Dev/Test/Prod)

Bu aşama, her ortam için altyapı değişikliklerini planlar:

1. **Terraform Kurulumu**: Belirtilen Terraform sürümünü yükler.
2. **Backend Hazırlığı**: Azure Storage hesabı ve container oluşturur (yoksa).
3. **Terraform Init**: Backend yapılandırması ile Terraform'u başlatır.
4. **Terraform Plan**: İlgili ortam için değişiklikleri planlar ve bir plan dosyası oluşturur.
5. **Plan Dosyasını Kaydetme**: Plan dosyasını pipeline artifact olarak kaydeder.

### Apply Aşaması (Dev/Test/Prod)

Bu aşama, planlanan değişiklikleri ilgili ortama uygular:

1. **Terraform Kurulumu**: Belirtilen Terraform sürümünü yükler.
2. **Plan Dosyasını İndirme**: Önceki aşamada oluşturulan plan dosyasını indirir.
3. **Terraform Init**: Backend yapılandırması ile Terraform'u başlatır.
4. **Terraform Apply**: Plan dosyasını kullanarak değişiklikleri uygular.

## Ortam Konfigürasyonları

Pipeline, farklı ortamlar için ayrı yapılandırmalar kullanır:

1. **Dev Ortamı**: Geliştirme ortamı için yapılandırmalar `environments/dev/terraform.tfvars` dosyasından alınır.
2. **Test Ortamı**: Test ortamı için yapılandırmalar `environments/test/terraform.tfvars` dosyasından alınır.
3. **Prod Ortamı**: Üretim ortamı için yapılandırmalar `environments/prod/terraform.tfvars` dosyasından alınır.

Her ortam için ayrı state dosyaları kullanılır:
- Dev: `terraform.tfstate`
- Test: `test.terraform.tfstate`
- Prod: `prod.terraform.tfstate`

## Güvenlik ve Kimlik Doğrulama

Pipeline, Azure kaynaklarına erişim için güvenli kimlik doğrulama yöntemleri kullanır:

1. **Service Principal**: Azure kaynaklarına erişim için Service Principal kullanılır.
2. **Değişken Grubu**: Kimlik bilgileri, Azure DevOps değişken grubunda güvenli bir şekilde saklanır.
3. **Ortam Değişkenleri**: Kimlik bilgileri, Terraform komutlarına ortam değişkenleri olarak aktarılır.

## Durum Yönetimi

Terraform state dosyaları, Azure Blob Storage'da merkezi olarak yönetilir:

1. **Storage Account**: State dosyaları için bir Azure Storage Account kullanılır.
2. **Container**: State dosyaları, `tfstate` adlı bir container'da saklanır.
3. **Ayrı State Dosyaları**: Her ortam için ayrı state dosyaları kullanılır.

## Onay Mekanizmaları

Pipeline, özellikle üretim ortamı için onay mekanizmaları içerir:

1. **Ortam Onayları**: Azure DevOps ortamları, dağıtım öncesi onay gerektiren şekilde yapılandırılabilir.
2. **Aşamalı Dağıtım**: Değişiklikler önce Dev, sonra Test ve en son Prod ortamına dağıtılır.
3. **Kontrol Noktaları**: Her aşama, bir önceki aşamanın başarılı olmasına bağlıdır.

## Hata Ayıklama ve Sorun Giderme

Pipeline'da sorun yaşandığında aşağıdaki adımları izleyebilirsiniz:

1. **Pipeline Logları**: Azure DevOps'ta pipeline çalıştırma loglarını inceleyin.
2. **Terraform Logları**: Terraform komutlarının çıktılarını kontrol edin.
3. **Backend Erişimi**: Storage Account'a erişim izinlerini doğrulayın.
4. **Service Principal**: Service Principal'in geçerli olduğunu ve gerekli izinlere sahip olduğunu kontrol edin.

## En İyi Uygulamalar

Pipeline'ı kullanırken aşağıdaki en iyi uygulamaları göz önünde bulundurun:

1. **Kod İncelemeleri**: Terraform değişiklikleri için Pull Request ve kod incelemeleri kullanın.
2. **Modülerlik**: Terraform kodunuzu modüler bir şekilde organize edin.
3. **Değişken Kullanımı**: Ortama özgü değerleri değişkenler aracılığıyla yönetin.
4. **Sürüm Kontrolü**: Terraform provider ve modül sürümlerini belirtin.
5. **Dokümantasyon**: Terraform kodunuzu ve modüllerinizi dokümante edin.
6. **Test Etme**: Değişiklikleri üretim ortamına dağıtmadan önce test ortamında test edin.
7. **Güvenlik Taramaları**: Terraform kodunuzu güvenlik açıkları için tarayın.

---

Bu pipeline, Terraform altyapı kodunuzun güvenli ve tutarlı bir şekilde dağıtılmasını sağlayarak, manuel müdahale ihtiyacını azaltır ve hata riskini minimize eder. Herhangi bir sorunuz veya öneriniz varsa, lütfen ekibimizle iletişime geçin.
