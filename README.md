## HomeWork #7 (terraform-2)
#### Самостоятельная работа
Создал с помощью packer отдельные образы для app и db:
- reddit-app-base
- reddit-db-base

Текущую конфигурацию terraform разбил на два модуля app и db, и создал модуль vpc для правил файрвола. В файле main.tf указываем откуда загружать модули [source]:

```
module "app" {
  source          = "../modules/app"
  public_key_path = "${var.public_key_path}"
  zone            = "${var.zone}"
  app_disk_image  = "${var.app_disk_image}"
}

module "db" {
  source          = "../modules/db"
  public_key_path = "${var.public_key_path}"
  zone            = "${var.zone}"
  db_disk_image   = "${var.db_disk_image}"
}

module "vpc" {
  source        = "../modules/vpc"
  source_ranges = ["${var.ip_access_range}"]
}

```
Модули загружаются с помощью команды `terraform get`
Разделил инфраструктуру на два окружения:
- stage
- prod

#### Задание со*
Для хранения текущего стейта настроил remote backend используя для этого GCS. Для создания GCS используется storage-bucket.tf после чего, происходит инициализация в stage и prod конфигурациях через terraform init. Если присутствовал локальный стейт - будет предложено его перенести в remote.
Если будет выполнено одновременное обращение к стейту, то сработает блокировка:

```
Error: Error locking state: Error acquiring the state lock: writing "gs://infra244120-tfstate-prod/prod/default.tflock" failed: googleapi: Error 412: Precondition Failed, conditionNotMet
Lock Info:
  ID:        1562610887460919
  Path:      gs://infra244120-tfstate-prod/prod/default.tflock
  Operation: OperationTypeApply
  Who:       appuser@test1
  Version:   0.11.11
  Created:   2019-07-08 18:34:47.348432387 +0000 UTC
  Info:


Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.
```

## HomeWork #6 (terraform-1)
#### Самостоятельная работа
Установил input переменную для приватного ключа:

`private_key = "${file(var.private_key_path)}"`

Установил input переменную для задания зоны в ресурсе
"google_compute_instance" "app":
```
variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "europe-west1-b"
}

resource "google_compute_instance" "app" {
  name         = "reddit-app"
  machine_type = "g1-small"
  zone         = "${var.zone}"
  tags         = ["reddit-app"]
...
```
Выполнил форматирование конфигурационных файлов:

`terraform fmt`

Создал файл terraform.tfvars.example, в котором будут указаны
переменные для образца:
```
project = "your_project_id"
public_key_path = "~/.ssh/appuser.pub"
private_key_path = "~/.ssh/appuser"
disk_image = "reddit-base"
```
#### Задание со*
Добавил ssh ключи пользователей в метаданне проекта:
```
resource "google_compute_project_metadata" "ssh-keys" {
  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)} appuser1:${file(var.public_key_path)} appuser2:${file(var.public_key_path)}"
  }
}

```
Ключи, не установленные в конфигурации terraform, но установленные на сервере, будут удалены. [Ссылка на документацию.](https://www.terraform.io/docs/providers/google/r/compute_project_metadata.html)


## HomeWork #5 (packer-base)
#### Самостоятельная работа

Создал файл variables.json и шаблон с переменными variables.json.example:
```
# variables.json
{
        "v_project_id": "infra-projectid",
        "v_source_image_family": "ubuntu-1604-lts",
        "v_machine_type": "f1-micro",
        "v_disk_size": "10",
        "v_disk_type": "pd-standard",
        "v_image_description": "reddit-app",
        "v_network": "default",
        "v_tags": "puma-server"
}

```

```
# variables.json.example
{
        "v_project_id": "infra-000001",
        "v_source_image_family": "ubuntu-1604-lts",
        "v_machine_type": "f1-micro",
        "v_disk_size": "10",
        "v_disk_type": "pd-standard",
        "v_image_description": "image-name",
        "v_network": "default",
        "v_tags": "puma-server"
}

```

В файле с конфигурацией сборки указываем переменные без установленных значений по умолчанию:
```
# ubuntu16.json
"variables": {
                "v_project_id": null,
                "v_source_image_family": null,
                "v_machine_type": null,
                "v_disk_size": null,
                "v_disk_type": null,
                "v_image_description": null,
                "v_network": null,
                "v_tags": null
        },

        "builders": [
        {
            "type": "googlecompute",
            "project_id": "{{user `v_project_id`}}",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "source_image_family": "{{user `v_source_image_family`}}",
            "zone": "europe-west1-b",
            "ssh_username": "vvorontsov",
            "machine_type": "{{user `v_machine_type`}}",
                        "disk_size": "{{user `v_disk_size`}}",
                        "disk_type": "{{user `v_disk_type`}}",
                        "image_description": "{{user `v_image_description`}}",
                        "network": "{{user `v_network`}}",
                        "tags": "{{user `v_tags`}}"
        }
    ],
```

Проверка конфигурации сборки:

`packer validate -var-file=variables.json ubuntu16.json`

Сборка образа:

`packer build -var-file=variables.json ubuntu16.json`
#### Задание со*
Написал скрипт для запуска VM из базового образа reddit-base:
```bash
# config-scripts/create-reddit-vm.sh

#!/bin/bash

gcloud compute instances create reddit-base\
  --image reddit-base-1561651318 \
  --machine-type=g1-small \
  --zone europe-west1-d \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=deploy.sh

```

## HomeWork #4 (cloud-testapp)
#### testapp socket:
```
testapp_IP = 35.241.132.155
testapp_port = 9292
```
#### Самостоятельная работа
Создание VM с помощью gcloud и с указанием startup-script:

```bash
gcloud compute instances create reddit-app \
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=startup_script.sh \
  --zone europe-west1-d 

```
#### Дополнительное задание
Создание правила файрвола default-puma-server с помощью gcloud:

```bash
gcloud compute firewall-rules create default-puma-server\
 --direction=INGRESS \
 --source-ranges=0.0.0.0/0 \
 --allow=tcp:9292 \
 --target-tags=puma-server
```

## HomeWork #3 (cloud-bastion)
#### VM IP adresses:
```
bastion_IP = 34.77.254.111
someinternalhost_IP = 10.132.0.6
```

#### Самостоятельная работа
Создаем в домашней директории пользователя файл конфигурации для ssh подключений ~/.ssh/config
```
### config
Host bastion
Hostname 34.77.254.111
User vvorontsov
Port 22

Host someinternalhost
Hostname 10.132.0.6
User vvorontsov
Port 22
ProxyCommand ssh bastion -W %h:%p
```
Теперь мы можем подключаться к хосту указывая только его имя из конфиг файла, например: ssh someinternalhost

Начиная с OpenSSH_7.3p1 можно использовать ProxyJump вместо ProxyCommand
https://wiki.gentoo.org/wiki/SSH_jump_host#Setup_2

```
Host someinternalhost
Hostname 10.132.0.6
User vvorontsov
Port 22
ProxyJump bastion
```
