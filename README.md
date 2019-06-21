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
Теперь мы можем подключаться к хосту указывая только его имя из конфиг файла, например: ssh someinternalhost

Начиная с OpenSSH_7.3p1 можно использовать ProxyJump вместо ProxyCommand
https://wiki.gentoo.org/wiki/SSH_jump_host#Setup_2

```
Host someinternalhost
Hostname 10.132.0.3
User vvorontsov
Port 22
ProxyJump bastion
```
