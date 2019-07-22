## HomeWork #10 (ansible-3)
#### Самостоятельная работа 
- Создал роли app и db
Инициализацию структуры каталогов роли можно выполнить с помощью команды:
`ansible-galaxy init <role_name>`

Из плейбуков перенес tasks, vars(defaults), templates, handlers, files в соответствующие файлы роли:
```
$ tree example-role
example-role
├── README.md
├── defaults
│ └── main.yml # <- Переменные и значения по умолчанию
├── files
├── handlers
│ └── main.yml # <-- Обработчики (aka хэндлеры)
├── meta
│ └── main.yml # <-- Информация о роли и зависимостях
├── tasks
│ └── main.yml # <-- Основные задачи в роли
├── templates
│ └── mongod.conf.j2 # <-- Шаблоны конфигурации
├── tests
│ ├── inventory # <-- Сценарии и данные для тестирования
│ └── test.yml
└── vars
└── main.yml # <-- Внутренние переменные роли
```
- Развернул окружение stage и prod
```
environments # tree .
.
├── prod
│   ├── credentials.yml
│   ├── group_vars
│   │   ├── all
│   │   ├── app
│   │   └── db
│   ├── inventory
│   └── requirements.yml
└── stage
    ├── credentials.yml
    ├── group_vars
    │   ├── all
    │   ├── app
    │   └── db
    ├── inventory
    └── requirements.yml

```
- Добавил роль nginx с помощью requirements.yml:
```
- src: jdauphant.nginx
  version: v2.21.1
```
`ansible-galaxy install -r environments/stage/requirements.yml`

Добавил правило для nginx в firewall:
```
resource "google_compute_firewall" "firewall_http" {
  name = "allow-http-default"

  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reddit-app"]
}

```

- Использовал Ansible Vault для шифрации файла:

`ansible-vault encrypt environments/stage/credentials.yml`

```
➜ ansible/environments/stage/credentials.yml
$ANSIBLE_VAULT;1.1;AES256
31313633666438623466303536313931333638363333646666386563383835366566316261396163
3765323765666338646138326365666662666134626537640a313936346261316230613733363064
61306331613566386534656366313361613232646434333333366666386433613166383165623837
3764383937663134340a653637623464353261613332643065653838666531623834333233363032
36326638373230366562366533383133633639326237613733363338663336376565376238636434
38393161396464666132663237336262653237656261333463303537373664616431663661363665
36353330623231666636373930383464363739376465626335353137386437613761323733393430
33623934323639353632393734316665346239396464623131613666383565313032623564646634
3238

```

## HomeWork #9 (ansible-2)
#### Самостоятельная работа
- Создал playbooks для конфигурации виртуалок app и db:

```  
# app.yml 
- name: Configure App
  hosts: app
  become: true
  vars:
   db_host: 10.132.0.61
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/appuser/db_config
        owner: appuser
        group: appuser

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
  - name: reload puma
    systemd: name=puma state=restarted
```

```
# db.yml
---
- name: Configure MongoDB
  hosts: db
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
  - name: restart mongod
    service: name=mongod state=restarted
```
И playbook для деплоя приложения:
```
# deploy.yml 
- name: Deploy App
  hosts: app
  tasks:
    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/appuser/reddit
        version: monolith
      notify: restart puma

    - name: bundle install
      bundler:
        state: present
        chdir: /home/appuser/reddit

  handlers:
  - name: restart puma
    become: true
    systemd: name=puma state=restarted
```
Все плейбуки инклюдятся в site.yml, который мы запускаем с использованием скрипта dynamic-inventory.sh:
```
# site.yml  
---
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
```
Также сбилдил новые образы с помощью packer. Изменил provisioners на ansible playbooks:
```
  "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/packer_app.yml"
        }
    ]

   "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/packer_db.yml"
        }
    ]

```
#### Использование dynamic inventory для GCP
Есть несколько способов получить динамический инвентори:
1. Использовать [gce inventory plugin](https://docs.ansible.com/ansible/2.5/scenario_guides/guide_gce.html#gce-dynamic-inventory)
2. Использовать скрипт который извлекает данные из terraform.tfstate. Например [terraform.py](https://github.com/mantl/terraform.py)
3. Использовать скрипт который получает выходные переменные terraform

## HomeWork #8 (ansible-1)
#### Самостоятельная работа
- Установил ansible(2.8.2)
- Создал inventory (ini и yaml формат)
```
# ini
[app]
appserver ansible_host=34.76.37.244

[db]
dbserver  ansible_host=104.155.41.230
```

```
# yaml
app:
  hosts:
    appserver:
      ansible_host: 34.76.37.244

db:
  hosts:
    dbserver:
      ansible_host: 104.155.41.230

```
- Создал playbook для клонирования репозитория:
```
- name: Clone
  hosts: app
  tasks:
    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/appuser/reddit

```
После выполнения плейбука удалил реп с помощью команды `ansible app -m command -a 'rm -rf ~/reddit'`. Повторное выполнение плейбука
клонирует репозиторий заново.
#### Задание со*
Написал скрипт для динамического создания inventory. В JSON шаблон подставляются выходные переменные terraform:
```
#!/bin/bash

cd ../terraform/stage

app_ip=$(terraform output app_external_ip)
db_ip=$(terraform output db_external_ip)

cd ../../ansible

inventory_template () {
cat <<EOF > inventory.json
{
    "_meta": {
      "hostvars": {}
    },
    "app": {
      "hosts": ["$app_ip"]
    },
    "db": {
      "hosts": ["$db_ip"]
    }
}
EOF
}

inventory_template
cat inventory.json
```

Использование динамического инвентори можно прописать в ansible.cfg:
```
[defaults]
inventory = ./dynamic_inventory.sh
```
Или указать с помощью флага `-i ./dynamic_inventory.sh`
```
➜  ansible git:(ansible-1) ✗ ansible-playbook -i dynamic-inventory.sh clone.yml

PLAY [Clone] ************************************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************************************
ok: [34.76.37.244]

TASK [Clone repo] *******************************************************************************************************************************
ok: [34.76.37.244]

PLAY RECAP **************************************************************************************************************************************
34.76.37.244               : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
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
