# vvorontsov_infra
vvorontsov Infra repository

## Home Work #3 (cloud-bastion)
#### VM IP adresses:
bastion_IP = 34.77.254.111

someinternalhost_IP = 10.132.0.3

#### Самостоятельное задание
Создаем в домашней директории пользователя файл конфигурации для ssh подключений ~/.ssh/config
```
### config
Host bastion
Hostname 34.77.254.111
User vvorontsov
Port 22

Host someinternalhost
Hostname 10.132.0.3
User vvorontsov
Port 22
ProxyCommand ssh bastion -W %h:%p
```
