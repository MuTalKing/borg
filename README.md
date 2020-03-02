# Borg Backup

#### Подготовка

- Пишем vagrantfile 
- Первое что мы делаем это устанавливаем Borg Backup на обе ВМ, но сначала устанавливаем epel репозиторий ```yum install epel-release -y; yum install borgbackup -y```
- Далее создаем пользователя borg на обоих машинах ```useradd -m borg```
- Необходимо прописать пароли для borg командой ```passwd borg```, почти все действия будут производиться от лица данного пользователя
- Так как borg будет делать резервные копии на сервер бэкапов, то нам необходимо включить авторизацию по ssh ключам, для этого необходимо сформировать ssh ключ на клиенте командой ```ssh-keygen``` под пользователем borg (на все вопросы нажимаем enter)
- Далее создаем на клиенте в ```/home/borg/.ssh/``` папку keys, куда перемещаем из ```/home/borg/.ssh/``` наши созданные ключи
- Далее на клиенте в ```/home/borg/.ssh/``` создаем файл с названием ```config``` и следующим содержимым:
```
Host borg-server
IdentityFile ~/.ssh/keys/id_rsa
```
Здесь указывается сервер к которому будем подключаться и путь до закрытого ключа на клиенте, т.е. на сервере у нас будет открытый ключ, а на клиенте закрытый ключ

- Далее необходимо скопировать открытый ключ из файла (с клиента) ```id_rsa.pub``` в файл ```/home/borg/.ssh/authorized_keys``` на сервер бэкапов и привести файл к такому виду:
```
'command="/usr/local/bin/borg serve" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkh81l3BvHNITaN/EbwaCtMjBqxP+e7qVey6kAeTR+SgZaxIwuVdSKl/LbEBM2PRIEk4swuo4WtRNTPGYjsBjtAJV6Njodb8qs+G0YNVTFbBSzQ0UUhU30jLCANsR+fpm14Bvg1FmI6swyhtpSwCJdSX1//9gfvm8LC0F0AU4u2JWvO7iggAdrPLOc8LThZcADJc7+yERfTwbFoHY6jVahDFtLIClIcCIrA8P66/WGCjviMTdTpz3A2FdEMcIwNsBFkTjwQjOXjllKNPIguNR0ejbnzAeUEIMUAB4ptSiVayYPPm8Py2rzj6gb08I8tfuMXBY/8M2vTFo4af4H29Cx borg@borg-client'

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkh81l3BvHNITaN/EbwaCtMjBqxP+e7qVey6kAeTR+SgZaxIwuVdSKl/LbEBM2PRIEk4swuo4WtRNTPGYjsBjtAJV6Njodb8qs+G0YNVTFbBSzQ0UUhU30jLCANsR+fpm14Bvg1FmI6swyhtpSwCJdSX1//9gfvm8LC0F0AU4u2JWvO7iggAdrPLOc8LThZcADJc7+yERfTwbFoHY6jVahDFtLIClIcCIrA8P66/WGCjviMTdTpz3A2FdEMcIwNsBFkTjwQjOXjllKNPIguNR0ejbnzAeUEIMUAB4ptSiVayYPPm8Py2rzj6gb08I8tfuMXBY/8M2vTFo4af4H29Cx borg@borg-client
```
Это два одинаковых публичных ключа, первый дает возможность программе Borg Backup подключаться по ssh по ключу, второй дает возможность подключиться администратору через обычный ssh сеанс

ВАЖНО!
Необходимо чтобы и на сервере и на клиенте в директориях ```/home/borg/.ssh``` для папок были права 700, а для файлов 600. Задается утилитой ```chmod```. Если не правильные права то работать не будет.

Далее необходимо в ```/etc/hosts``` на клиенте ввести сопоставление адреса и имени сервера, для клиента:
```
192.168.10.22 borg-server
```
На сервере:
```
192.168.10.23 borg-client
```
Протестировать работоспособность можно введя под пользователем borg (на клиенте), команду ```ssh borg@borg-server```, все должно работать.

#### Настройка Borg Backup

- Далее нам надо инициализировать с клиента репозитории Borg Backup командой ```borg init -e none borg@borg-server:MyBorgRepo```, там будут храниться файлы резервных копий
- Далее мы можем командой ```borg create --stats --list borg@borg-server:MyBorgRepo::"MyFirstBackup-{now:%Y-%m-%d_%H:%M:%S}" /etc``` создать свою первую резервную копию:

![Image alt](https://github.com/MuTalKing/borg/blob/master/Borg.jpg)
- Посмотреть бэкапы можно командой ```borg list borg@borg-server:MyBorgRepo```
- Далее мы можем автоматизировать выполнение резервных копий, написав обычный bash скрипт, куда добавляем наши задания и политики удаления и можно добавить bash скрипт в cron.
- Пример простого скрипта:
```
#!/bin/bash
BORG_SERVER="borg@borg-server"
NAMEOFBACKUP=${1}
DIRS=${2}
REPOSITORY="${BORG_SERVER}:$(hostname)-${NAMEOFBACKUP}"

borg create --list -v --stats \
  $REPOSITORY::"files-{now:%Y-%m-%d_%H:%M:%S}" \
  $(echo $DIRS | tr ',' ' ') || \
   echo "borg create failed"
```

Очень помогла вот эта статья: https://habr.com/ru/company/flant/blog/420055/
