## Задание 1. Организация шифрования содержимого S3-бакета.  
Используя конфигурации, выполненные в рамках ДЗ на предыдущем занятии, добавить к созданному ранее bucket S3 возможность шифрования Server-Side, используя общий ключ;  
Включить шифрование SSE-S3 bucket S3 для шифрования всех вновь добавляемых объектов в данный bucket  
```
iv_art@Pappa-wsl:~/terraform-cloud/15-3$ cat bucket.tf
// Use sa
resource "yandex_iam_service_account" "sa" {
  name      = "bucket-holder"
}

// Grant permissions
resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = "${var.yandex_folder_id}"
  role = "editor"
  member      = "serviceAccount:${yandex_iam_service_account.sa.id}"
  depends_on = [yandex_iam_service_account.sa]
}

// Create access key
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "static access key for object storage"
}

// Create KMS key

resource "yandex_kms_symmetric_key" "key-a" {
  name              = "example-symetric-key"
  description       = "description for key"
  default_algorithm = "AES_128"
  rotation_period   = "48h"
}


// Create bucket
resource "yandex_storage_bucket" "s3_bucket" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "ivart-s3-bucket"
// server encrytion
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.key-a.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

// Upload picture
resource "yandex_storage_object" "test-object" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "ivart-s3-bucket"
  key        = "my-image.png"
  source     = "sands.png"
  depends_on = [yandex_storage_bucket.s3_bucket]
  acl        = "public-read"
}

iv_art@Pappa-wsl:~/terraform-cloud/15-3$ terraform apply
...

  Enter a value: yes

yandex_kms_symmetric_key.key-a: Creating...
yandex_vpc_network.vpc-network: Creating...
yandex_iam_service_account.sa: Creating...
yandex_kms_symmetric_key.key-a: Creation complete after 4s [id=abj5cilcvlqlgo1s8u6i]
yandex_vpc_network.vpc-network: Creation complete after 5s [id=enp94rmv2e7tqfv63iql]
yandex_vpc_subnet.public: Creating...
yandex_iam_service_account.sa: Creation complete after 5s [id=ajeuldqepl3788gr2pc8]
yandex_iam_service_account_static_access_key.sa-static-key: Creating...
yandex_resourcemanager_folder_iam_member.sa-editor: Creating...
yandex_iam_service_account_static_access_key.sa-static-key: Creation complete after 1s [id=ajeqifnm2abcrl9ei71a]
yandex_storage_bucket.s3_bucket: Creating...
yandex_vpc_subnet.public: Creation complete after 2s [id=e9bf2u5vnhscn10ovuon]
yandex_resourcemanager_folder_iam_member.sa-editor: Creation complete after 3s [id=b1gngdmp3o039dgvg8r5/editor/serviceAccount:ajeuldqepl3788gr2pc8]
yandex_storage_bucket.s3_bucket: Still creating... [10s elapsed]
yandex_storage_bucket.s3_bucket: Still creating... [20s elapsed]
yandex_storage_bucket.s3_bucket: Still creating... [30s elapsed]
yandex_storage_bucket.s3_bucket: Still creating... [40s elapsed]
yandex_storage_bucket.s3_bucket: Still creating... [50s elapsed]
yandex_storage_bucket.s3_bucket: Still creating... [1m0s elapsed]
yandex_storage_bucket.s3_bucket: Creation complete after 1m6s [id=ivart-s3-bucket]
yandex_storage_object.test-object: Creating...
yandex_storage_object.test-object: Creation complete after 1s [id=my-image.png]

Apply complete! Resources: 8 added, 0 changed, 0 destroyed.
iv_art@Pappa-wsl:~/terraform-cloud/15-3$

iv_art@Pappa-wsl:~/terraform-cloud/15-3$ yc kms symmetric-key list
+----------------------+----------------------+----------------------+-------------------+---------------------+--------+
|          ID          |         NAME         |  PRIMARY VERSION ID  | DEFAULT ALGORITHM |     CREATED AT      | STATUS |
+----------------------+----------------------+----------------------+-------------------+---------------------+--------+
| abj5cilcvlqlgo1s8u6i | example-symetric-key | abjs7dle6glshpp54imh | AES_128           | 2022-09-03 06:36:43 | ACTIVE |
+----------------------+----------------------+----------------------+-------------------+---------------------+--------+
```
Смотрим в облаке  
![image](https://user-images.githubusercontent.com/87374285/188259194-6fcc40b4-f318-4d19-b11f-a21f5381dc21.png)  
