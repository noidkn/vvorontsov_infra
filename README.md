## Home Work #3 (cloud-bastion)
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

## Home Work #4 (cloud-testapp)
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
