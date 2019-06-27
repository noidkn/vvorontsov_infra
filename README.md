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
