# **HW-2 | Установка и настройка PostgteSQL в контейнере Docker**




## **Цель:**
развернуть ВМ в GCP/ЯО/Аналоги
установить туда докер
установить PostgreSQL в Docker контейнере
настроить контейнер для внешнего подключения




## **Описание/Пошаговая инструкция выполнения домашнего задания:**
- сделать в GCE/ЯО/Аналоги инстанс с Ubuntu 20.04
- поставить на нем Docker Engine
- сделать каталог /var/lib/postgres
- развернуть контейнер с PostgreSQL 14 смонтировав в него /var/lib/postgres
- развернуть контейнер с клиентом postgres
- подключится из контейнера с клиентом к контейнеру с сервером и сделать
таблицу с парой строк
- подключится к контейнеру с сервером с ноутбука/компьютера извне инстансов GCP/ЯО/Аналоги
- удалить контейнер с сервером
- создать его заново
- подключится снова из контейнера с клиентом к контейнеру с сервером
- проверить, что данные остались на месте
- оставляйте в ЛК ДЗ комментарии что и как вы делали и как боролись с проблемами



## **Выполнение домашнего задания**

### **Установка VM с Docker Engine**

  Воспользуемся **vagrant**, загрузим образ **ubuntu2004**
```console
[root@test2 hw-2]# vagrant --version
Vagrant 2.4.1
[root@test2 hw-2]# vagrant box add generic/ubuntu2004 --provide=virtualbox
==> box: Loading metadata for box 'generic/ubuntu2004'
    box: URL: https://vagrantcloud.com/api/v2/vagrant/generic/ubuntu2004
==> box: Adding box 'generic/ubuntu2004' (v4.3.12) for provider: virtualbox (amd64)
    box: Downloading: https://vagrantcloud.com/generic/boxes/ubuntu2004/versions/4.3.12/providers/virtualbox/amd64/vagrant.box
Download redirected to host: api.cloud.hashicorp.com
    box: Calculating and comparing box checksum...
==> box: Successfully added box 'generic/ubuntu2004' (v4.3.12) for 'virtualbox (amd64)'!
```

  Создадим файл **Vagrantfile**:
```console
[root@test2 hw-2]# cat Vagrantfile 
$script1 = <<-SCRIPT
echo start custom provizioning...
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get -y install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install the Docker packages.
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
SCRIPT


Vagrant.configure("2") do |config|

  config.vm.define "vmnode" do |node|
    node.vm.network "private_network", ip: "192.168.60.200"
    node.vm.hostname = "vnmode"
    node.vm.define "vmnode"
    node.vm.box_download_insecure = true
    node.vm.box = "generic/ubuntu2004"
    node.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.memory = "1024"
      vb.cpus = 2
    end
    node.vm.provision "shell", inline: $script1
    #node.vm.provision "ansible", playbook: "test.yml"
  end

end
```

  Запускаем провиженинг VM:
```console
[root@test2 hw-2]# vagrant up vmnode
Bringing machine 'vmnode' up with 'virtualbox' provider...
==> vmnode: Importing base box 'generic/ubuntu2004'...
==> vmnode: Matching MAC address for NAT networking...
==> vmnode: Checking if box 'generic/ubuntu2004' version '4.3.12' is up to date...
==> vmnode: Setting the name of the VM: hw-2_vmnode_1732031042280_75591
==> vmnode: Clearing any previously set network interfaces...
==> vmnode: Preparing network interfaces based on configuration...
    vmnode: Adapter 1: nat
    vmnode: Adapter 2: hostonly
==> vmnode: Forwarding ports...
    vmnode: 22 (guest) => 2222 (host) (adapter 1)
==> vmnode: Running 'pre-boot' VM customizations...
==> vmnode: Booting VM...
==> vmnode: Waiting for machine to boot. This may take a few minutes...
    vmnode: SSH address: 127.0.0.1:2222
    vmnode: SSH username: vagrant
    vmnode: SSH auth method: private key
    vmnode: 
    vmnode: Vagrant insecure key detected. Vagrant will automatically replace
    vmnode: this with a newly generated keypair for better security.
    vmnode: 
    vmnode: Inserting generated public key within guest...
    vmnode: Removing insecure key from the guest if it's present...
    vmnode: Key inserted! Disconnecting and reconnecting using new SSH key...
==> vmnode: Machine booted and ready!
==> vmnode: Checking for guest additions in VM...
    vmnode: The guest additions on this VM do not match the installed version of
    vmnode: VirtualBox! In most cases this is fine, but in rare cases it can
    vmnode: prevent things such as shared folders from working properly. If you see
    vmnode: shared folder errors, please make sure the guest additions within the
    vmnode: virtual machine match the version of VirtualBox you have installed on
    vmnode: your host and reload your VM.
    vmnode: 
    vmnode: Guest Additions Version: 6.1.38
    vmnode: VirtualBox Version: 7.0
==> vmnode: Setting hostname...
==> vmnode: Configuring and enabling network interfaces...
==> vmnode: Running provisioner: shell...
    vmnode: Running: inline script
    vmnode: start custom provizioning...
    vmnode: Get:1 http://security.ubuntu.com/ubuntu focal-security InRelease [128 kB]
    vmnode: Hit:2 http://us.archive.ubuntu.com/ubuntu focal InRelease
    vmnode: Get:3 http://us.archive.ubuntu.com/ubuntu focal-updates InRelease [128 kB]
    vmnode: Get:4 http://security.ubuntu.com/ubuntu focal-security/main amd64 Packages [3,302 kB]
    vmnode: Get:5 http://us.archive.ubuntu.com/ubuntu focal-backports InRelease [128 kB]
    vmnode: Get:6 http://us.archive.ubuntu.com/ubuntu focal-updates/main amd64 Packages [3,675 kB]
    vmnode: Get:7 http://security.ubuntu.com/ubuntu focal-security/main i386 Packages [834 kB]
    vmnode: Get:8 http://security.ubuntu.com/ubuntu focal-security/main Translation-en [484 kB]
    vmnode: Get:9 http://security.ubuntu.com/ubuntu focal-security/main amd64 c-n-f Metadata [14.3 kB]
    vmnode: Get:10 http://security.ubuntu.com/ubuntu focal-security/restricted amd64 Packages [3,247 kB]
    vmnode: Get:11 http://security.ubuntu.com/ubuntu focal-security/restricted i386 Packages [38.6 kB]
    vmnode: Get:12 http://security.ubuntu.com/ubuntu focal-security/restricted Translation-en [456 kB]
    vmnode: Get:13 http://security.ubuntu.com/ubuntu focal-security/restricted amd64 c-n-f Metadata [548 B]
    vmnode: Get:14 http://security.ubuntu.com/ubuntu focal-security/universe i386 Packages [682 kB]
    vmnode: Get:15 http://us.archive.ubuntu.com/ubuntu focal-updates/main i386 Packages [1,053 kB]
    vmnode: Get:16 http://security.ubuntu.com/ubuntu focal-security/universe amd64 Packages [1,016 kB]
    vmnode: Get:17 http://us.archive.ubuntu.com/ubuntu focal-updates/main Translation-en [563 kB]
    vmnode: Get:18 http://us.archive.ubuntu.com/ubuntu focal-updates/main amd64 c-n-f Metadata [17.8 kB]
    vmnode: Get:19 http://us.archive.ubuntu.com/ubuntu focal-updates/restricted i386 Packages [39.9 kB]
    vmnode: Get:20 http://us.archive.ubuntu.com/ubuntu focal-updates/restricted amd64 Packages [3,370 kB]
    vmnode: Get:21 http://security.ubuntu.com/ubuntu focal-security/universe Translation-en [214 kB]
    vmnode: Get:22 http://security.ubuntu.com/ubuntu focal-security/universe amd64 c-n-f Metadata [21.4 kB]
    vmnode: Get:23 http://security.ubuntu.com/ubuntu focal-security/multiverse amd64 Packages [24.8 kB]
    vmnode: Get:24 http://security.ubuntu.com/ubuntu focal-security/multiverse i386 Packages [7,204 B]
    vmnode: Get:25 http://security.ubuntu.com/ubuntu focal-security/multiverse Translation-en [5,968 B]
    vmnode: Get:26 http://security.ubuntu.com/ubuntu focal-security/multiverse amd64 c-n-f Metadata [540 B]
    vmnode: Get:27 http://us.archive.ubuntu.com/ubuntu focal-updates/restricted Translation-en [472 kB]
    vmnode: Get:28 http://us.archive.ubuntu.com/ubuntu focal-updates/restricted amd64 c-n-f Metadata [548 B]
    vmnode: Get:29 http://us.archive.ubuntu.com/ubuntu focal-updates/universe i386 Packages [810 kB]
    vmnode: Get:30 http://us.archive.ubuntu.com/ubuntu focal-updates/universe amd64 Packages [1,238 kB]
    vmnode: Get:31 http://us.archive.ubuntu.com/ubuntu focal-updates/universe Translation-en [297 kB]
    vmnode: Get:32 http://us.archive.ubuntu.com/ubuntu focal-updates/universe amd64 c-n-f Metadata [28.3 kB]
    vmnode: Get:33 http://us.archive.ubuntu.com/ubuntu focal-updates/multiverse amd64 Packages [27.0 kB]
    vmnode: Get:34 http://us.archive.ubuntu.com/ubuntu focal-updates/multiverse i386 Packages [8,440 B]
    vmnode: Get:35 http://us.archive.ubuntu.com/ubuntu focal-updates/multiverse Translation-en [7,936 B]
    vmnode: Get:36 http://us.archive.ubuntu.com/ubuntu focal-updates/multiverse amd64 c-n-f Metadata [612 B]
    vmnode: Fetched 22.3 MB in 6s (3,765 kB/s)
    vmnode: Reading package lists...
    vmnode: Reading package lists...
    vmnode: Building dependency tree...
    vmnode: Reading state information...
    vmnode: The following additional packages will be installed:
    vmnode:   libcurl4
    vmnode: The following packages will be upgraded:
    vmnode:   ca-certificates curl libcurl4
    vmnode: 3 upgraded, 0 newly installed, 0 to remove and 123 not upgraded.
    vmnode: Need to get 556 kB of archives.
    vmnode: After this operation, 9,216 B of additional disk space will be used.
    vmnode: Get:1 http://us.archive.ubuntu.com/ubuntu focal-updates/main amd64 ca-certificates all 20240203~20.04.1 [159 kB]
    vmnode: Get:2 http://us.archive.ubuntu.com/ubuntu focal-updates/main amd64 curl amd64 7.68.0-1ubuntu2.24 [162 kB]
    vmnode: Get:3 http://us.archive.ubuntu.com/ubuntu focal-updates/main amd64 libcurl4 amd64 7.68.0-1ubuntu2.24 [235 kB]
    vmnode: dpkg-preconfigure: unable to re-open stdin: No such file or directory
    vmnode: Fetched 556 kB in 3s (162 kB/s)
(Reading database ... 111971 files and directories currently installed.)
    vmnode: Preparing to unpack .../ca-certificates_20240203~20.04.1_all.deb ...
    vmnode: Unpacking ca-certificates (20240203~20.04.1) over (20230311ubuntu0.20.04.1) ...
    vmnode: Preparing to unpack .../curl_7.68.0-1ubuntu2.24_amd64.deb ...
    vmnode: Unpacking curl (7.68.0-1ubuntu2.24) over (7.68.0-1ubuntu2.21) ...
    vmnode: Preparing to unpack .../libcurl4_7.68.0-1ubuntu2.24_amd64.deb ...
    vmnode: Unpacking libcurl4:amd64 (7.68.0-1ubuntu2.24) over (7.68.0-1ubuntu2.21) ...
    vmnode: Setting up ca-certificates (20240203~20.04.1) ...
    vmnode: Updating certificates in /etc/ssl/certs...
    vmnode: rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
    vmnode: 14 added, 5 removed; done.
    vmnode: Setting up libcurl4:amd64 (7.68.0-1ubuntu2.24) ...
    vmnode: Setting up curl (7.68.0-1ubuntu2.24) ...
    vmnode: Processing triggers for man-db (2.9.1-1) ...
    vmnode: Processing triggers for libc-bin (2.31-0ubuntu9.14) ...
    vmnode: Processing triggers for ca-certificates (20240203~20.04.1) ...
    vmnode: Updating certificates in /etc/ssl/certs...
    vmnode: 0 added, 0 removed; done.
    vmnode: Running hooks in /etc/ca-certificates/update.d...
    vmnode: done.
    vmnode: Hit:1 http://us.archive.ubuntu.com/ubuntu focal InRelease
    vmnode: Hit:2 http://us.archive.ubuntu.com/ubuntu focal-updates InRelease
    vmnode: Hit:3 http://security.ubuntu.com/ubuntu focal-security InRelease
    vmnode: Get:4 https://download.docker.com/linux/ubuntu focal InRelease [57.7 kB]
    vmnode: Hit:5 http://us.archive.ubuntu.com/ubuntu focal-backports InRelease
    vmnode: Get:6 https://download.docker.com/linux/ubuntu focal/stable amd64 Packages [51.8 kB]
    vmnode: Fetched 109 kB in 1s (80.8 kB/s)
    vmnode: Reading package lists...
    vmnode: Reading package lists...
    vmnode: Building dependency tree...
    vmnode: Reading state information...
    vmnode: The following additional packages will be installed:
    vmnode:   docker-ce-rootless-extras pigz slirp4netns
    vmnode: Suggested packages:
    vmnode:   aufs-tools cgroupfs-mount | cgroup-lite
    vmnode: The following NEW packages will be installed:
    vmnode:   containerd.io docker-buildx-plugin docker-ce docker-ce-cli
    vmnode:   docker-ce-rootless-extras docker-compose-plugin pigz slirp4netns
    vmnode: 0 upgraded, 8 newly installed, 0 to remove and 123 not upgraded.
    vmnode: Need to get 123 MB of archives.
    vmnode: After this operation, 442 MB of additional disk space will be used.
    vmnode: Get:1 http://us.archive.ubuntu.com/ubuntu focal/universe amd64 pigz amd64 2.4-1 [57.4 kB]
    vmnode: Get:2 https://download.docker.com/linux/ubuntu focal/stable amd64 containerd.io amd64 1.7.23-1 [29.5 MB]
    vmnode: Get:3 http://us.archive.ubuntu.com/ubuntu focal/universe amd64 slirp4netns amd64 0.4.3-1 [74.3 kB]
    vmnode: Get:4 https://download.docker.com/linux/ubuntu focal/stable amd64 docker-buildx-plugin amd64 0.17.1-1~ubuntu.20.04~focal [30.3 MB]
    vmnode: Get:5 https://download.docker.com/linux/ubuntu focal/stable amd64 docker-ce-cli amd64 5:27.3.1-1~ubuntu.20.04~focal [15.0 MB]
    vmnode: Get:6 https://download.docker.com/linux/ubuntu focal/stable amd64 docker-ce amd64 5:27.3.1-1~ubuntu.20.04~focal [25.6 MB]
    vmnode: Get:7 https://download.docker.com/linux/ubuntu focal/stable amd64 docker-ce-rootless-extras amd64 5:27.3.1-1~ubuntu.20.04~focal [9,597 kB]
    vmnode: Get:8 https://download.docker.com/linux/ubuntu focal/stable amd64 docker-compose-plugin amd64 2.29.7-1~ubuntu.20.04~focal [12.6 MB]
    vmnode: dpkg-preconfigure: unable to re-open stdin: No such file or directory
    vmnode: Fetched 123 MB in 16s (7,877 kB/s)
    vmnode: Selecting previously unselected package pigz.
(Reading database ... 111980 files and directories currently installed.)
    vmnode: Preparing to unpack .../0-pigz_2.4-1_amd64.deb ...
    vmnode: Unpacking pigz (2.4-1) ...
    vmnode: Selecting previously unselected package containerd.io.
    vmnode: Preparing to unpack .../1-containerd.io_1.7.23-1_amd64.deb ...
    vmnode: Unpacking containerd.io (1.7.23-1) ...
    vmnode: Selecting previously unselected package docker-buildx-plugin.
    vmnode: Preparing to unpack .../2-docker-buildx-plugin_0.17.1-1~ubuntu.20.04~focal_amd64.deb ...
    vmnode: Unpacking docker-buildx-plugin (0.17.1-1~ubuntu.20.04~focal) ...
    vmnode: Selecting previously unselected package docker-ce-cli.
    vmnode: Preparing to unpack .../3-docker-ce-cli_5%3a27.3.1-1~ubuntu.20.04~focal_amd64.deb ...
    vmnode: Unpacking docker-ce-cli (5:27.3.1-1~ubuntu.20.04~focal) ...
    vmnode: Selecting previously unselected package docker-ce.
    vmnode: Preparing to unpack .../4-docker-ce_5%3a27.3.1-1~ubuntu.20.04~focal_amd64.deb ...
    vmnode: Unpacking docker-ce (5:27.3.1-1~ubuntu.20.04~focal) ...
    vmnode: Selecting previously unselected package docker-ce-rootless-extras.
    vmnode: Preparing to unpack .../5-docker-ce-rootless-extras_5%3a27.3.1-1~ubuntu.20.04~focal_amd64.deb ...
    vmnode: Unpacking docker-ce-rootless-extras (5:27.3.1-1~ubuntu.20.04~focal) ...
    vmnode: Selecting previously unselected package docker-compose-plugin.
    vmnode: Preparing to unpack .../6-docker-compose-plugin_2.29.7-1~ubuntu.20.04~focal_amd64.deb ...
    vmnode: Unpacking docker-compose-plugin (2.29.7-1~ubuntu.20.04~focal) ...
    vmnode: Selecting previously unselected package slirp4netns.
    vmnode: Preparing to unpack .../7-slirp4netns_0.4.3-1_amd64.deb ...
    vmnode: Unpacking slirp4netns (0.4.3-1) ...
    vmnode: Setting up slirp4netns (0.4.3-1) ...
    vmnode: Setting up docker-buildx-plugin (0.17.1-1~ubuntu.20.04~focal) ...
    vmnode: Setting up containerd.io (1.7.23-1) ...
    vmnode: Created symlink /etc/systemd/system/multi-user.target.wants/containerd.service → /lib/systemd/system/containerd.service.
    vmnode: Setting up docker-compose-plugin (2.29.7-1~ubuntu.20.04~focal) ...
    vmnode: Setting up docker-ce-cli (5:27.3.1-1~ubuntu.20.04~focal) ...
    vmnode: Setting up pigz (2.4-1) ...
    vmnode: Setting up docker-ce-rootless-extras (5:27.3.1-1~ubuntu.20.04~focal) ...
    vmnode: Setting up docker-ce (5:27.3.1-1~ubuntu.20.04~focal) ...
    vmnode: Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /lib/systemd/system/docker.service.
    vmnode: Created symlink /etc/systemd/system/sockets.target.wants/docker.socket → /lib/systemd/system/docker.socket.
    vmnode: Processing triggers for man-db (2.9.1-1) ...
    vmnode: Processing triggers for systemd (245.4-4ubuntu3.22) ...
```


  Проверяем статус VM:
```console
[root@test2 hw-2]# vagrant status
Current machine states:

vmnode                    running (virtualbox)

The VM is running. To stop this VM, you can run `vagrant halt` to
shut it down forcefully, or you can run `vagrant suspend` to simply
suspend the virtual machine. In either case, to restart it again,
simply run `vagrant up`.
```


### **Запуск контейнера с Postgresql**

  На локальном компьютере генерируем пароль для БД, экспортируем его в переменную окружения **PG_PASS**,
также создаем сеть **pgnet**, в которой будем поднимать контейнер с postgres.
```console
[root@test2 hw-2]# export PG_PASS="$(pwgen -n 12 1)"

[root@test2 hw-2]# vagrant ssh vmnode -- sudo docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

[root@test2 hw-2]# vagrant ssh vmnode -- sudo docker network create -d bridge pgnet
d68a7aef35dc405a2f1d020841bf55fd262a83188db2be62936f63e5b746d7c6
```

  Создаем и запускаем контейнер с postgres:
```console
[root@test2 hw-2]# vagrant ssh vmnode -- sudo docker run -d --name postgres14 --network=pgnet -e POSTGRES_PASSWORD="${PG_PASS}" -v /var/lib/postgres:/var/lib/postgresql/data -p 5432:5432 postgres:14.14
ec88ae38d0d64501c3888bd2d7cfd7a0710f881eb6846e64e9e2aa04cbaca639
 
[root@test2 hw-2]# vagrant ssh vmnode -- sudo docker ps
CONTAINER ID   IMAGE            COMMAND                  CREATED          STATUS          PORTS                    NAMES
ec88ae38d0d6   postgres:14.14   "docker-entrypoint.s…"   25 seconds ago   Up 24 seconds   0.0.0.0:5432->5432/tcp   postgres14

[root@test2 hw-2]# vagrant ssh vmnode -- sudo docker logs ec88ae38d0d6
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.utf8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/data ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... Etc/UTC
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

initdb: warning: enabling "trust" authentication for local connections
You can change this by editing pg_hba.conf or using the option -A, or
--auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    pg_ctl -D /var/lib/postgresql/data -l logfile start

waiting for server to start....2024-11-19 16:05:16.702 UTC [49] LOG:  starting PostgreSQL 14.14 (Debian 14.14-1.pgdg120+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
2024-11-19 16:05:16.704 UTC [49] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2024-11-19 16:05:16.709 UTC [50] LOG:  database system was shut down at 2024-11-19 16:05:16 UTC
2024-11-19 16:05:16.714 UTC [49] LOG:  database system is ready to accept connections
 done
server started

/usr/local/bin/docker-entrypoint.sh: ignoring /docker-entrypoint-initdb.d/*

2024-11-19 16:05:16.860 UTC [49] LOG:  received fast shutdown request
waiting for server to shut down....2024-11-19 16:05:16.861 UTC [49] LOG:  aborting any active transactions
2024-11-19 16:05:16.864 UTC [49] LOG:  background worker "logical replication launcher" (PID 56) exited with exit code 1
2024-11-19 16:05:16.864 UTC [51] LOG:  shutting down
2024-11-19 16:05:16.878 UTC [49] LOG:  database system is shut down
 done
server stopped

PostgreSQL init process complete; ready for start up.

2024-11-19 16:05:17.027 UTC [1] LOG:  starting PostgreSQL 14.14 (Debian 14.14-1.pgdg120+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
2024-11-19 16:05:17.027 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2024-11-19 16:05:17.028 UTC [1] LOG:  listening on IPv6 address "::", port 5432
2024-11-19 16:05:17.030 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2024-11-19 16:05:17.034 UTC [62] LOG:  database system was shut down at 2024-11-19 16:05:16 UTC
2024-11-19 16:05:17.038 UTC [1] LOG:  database system is ready to accept connections
```


### **Создание тестовой таблицы используя контейнер с клиентом postgres**

  Подключаемся к VM, экспортируем переменные окружения для подключения к инстансу postgres в контейнере   
и проверяем подключение:
```console
[root@test2 hw-2]# vagrant ssh vmnode
Last login: Tue Nov 19 20:04:28 2024 from 10.0.2.2
vagrant@vnmode:~$  

vagrant@vnmode:~$ export PG_IP="$(sudo docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgres14)"
vagrant@vnmode:~$ export PG_PASS="$(sudo docker exec -it postgres14 bash -c 'echo -n $POSTGRES_PASSWORD')"
vagrant@vnmode:~$ sudo docker run --rm --network=pgnet -e PGPASSWORD="${PG_PASS}" postgres:14.14 psql -h "${PG_IP}" -U postgres -w -c "select 1"
 ?column? 
----------
        1
(1 row)
```
  
  Создаем тестовую таблицу:
```console
vagrant@vnmode:~$ sudo docker run --rm --network=pgnet -e PGPASSWORD="${PG_PASS}" postgres:14.14 psql -h "${PG_IP}" -U postgres -w -c """
> create table persons(id serial, first_name text, second_name text);
> insert into persons(first_name, second_name) values('ivan', 'ivanov');
> insert into persons(first_name, second_name) values('petr', 'petrov');
> """
INSERT 0 1
vagrant@vnmode:~$ 
vagrant@vnmode:~$ sudo docker run --rm --network=pgnet -e PGPASSWORD="${PG_PASS}" postgres:14.14 psql -h "${PG_IP}" -U postgres -w -c "select * from persons"
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
```


### **Проверка подключения к инстансу postgres с локального компьютера:**
  Для подключение используем ip адрес указанный в Vagrantfile, а также экспортируем пароль в переменную окружения **PGPASSWORD**
```console
[root@test2 hw-2]# PGPASSWORD="${PG_PASS}" psql -h 192.168.60.200 -U postgres -w -c "select * from persons"
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
```


### **Удаляем контейнер postgres с VM:** 
```console
[root@test2 hw-2]# vagrant ssh vmnode -- sudo docker ps 
CONTAINER ID   IMAGE            COMMAND                  CREATED       STATUS       PORTS                    NAMES
ec88ae38d0d6   postgres:14.14   "docker-entrypoint.s…"   4 hours ago   Up 4 hours   0.0.0.0:5432->5432/tcp   postgres14

[root@test2 hw-2]# vagrant ssh vmnode -- sudo docker stop ec88ae38d0d6 
ec88ae38d0d6
[root@test2 hw-2]# vagrant ssh vmnode -- sudo docker rm ec88ae38d0d6 
ec88ae38d0d6

[root@test2 hw-2]# vagrant ssh vmnode -- sudo docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```


### **Повторно создаем контейнер с postgres**

  Создаем контейнер с postgres повторно, использую директорию с данными от предыдущего инстанса и используя новое имя для контейнера:
```console
[root@test2 hw-2]# ssh vmnode -- sudo docker run -d --name postgres14-new --network=pgnet -e POSTGRES_PASSWORD="${PG_PASS}" -v /var/lib/postgres:/var/lib/postgresql/data -p 5432:5432 postgres:14.14
ssh: Could not resolve hostname vmnode: Name or service not known
[root@test2 hw-2]# vagrant ssh vmnode -- sudo docker run -d --name postgres14-new --network=pgnet -e POSTGRES_PASSWORD="${PG_PASS}" -v /var/lib/postgres:/var/lib/postgresql/data -p 5432:5432 postgres:14.14
92de61489ec147dd758ff2813e38eb6ebcd6e3c828eed9b466495e999389ee8e
```

  Проверяем успешность создания и запуска инстанса:
```console
[root@test2 hw-2]# vagrant ssh vmnode -- sudo docker ps 
CONTAINER ID   IMAGE            COMMAND                  CREATED          STATUS          PORTS                    NAMES
92de61489ec1   postgres:14.14   "docker-entrypoint.s…"   32 seconds ago   Up 32 seconds   0.0.0.0:5432->5432/tcp   postgres14-new
[root@test2 hw-2]# vagrant ssh vmnode -- sudo docker logs 92de61489ec1

PostgreSQL Database directory appears to contain a database; Skipping initialization

2024-11-19 20:35:52.828 UTC [1] LOG:  starting PostgreSQL 14.14 (Debian 14.14-1.pgdg120+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
2024-11-19 20:35:52.828 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2024-11-19 20:35:52.828 UTC [1] LOG:  listening on IPv6 address "::", port 5432
2024-11-19 20:35:52.831 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2024-11-19 20:35:52.836 UTC [26] LOG:  database system was shut down at 2024-11-19 20:28:57 UTC
2024-11-19 20:35:52.841 UTC [1] LOG:  database system is ready to accept connections
``` 


### **Проверяем сохранность данных**
  Подключаемся к VM, и затем используя пароль созданный при инициализации первой бд, подключаемся к инстансу postgres и проверяем данные: 
```console  
[root@test2 hw-2]# vagrant ssh vmnode 
Last login: Tue Nov 19 20:47:26 2024 from 10.0.2.2
vagrant@vnmode:~$ export PG_IP="$(sudo docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgres14-new)"
vagrant@vnmode:~$ export PG_PASS="######"
vagrant@vnmode:~$ sudo docker run --rm --network=pgnet -e PGPASSWORD="${PG_PASS}" postgres:14.14 psql -h "${PG_IP}" -U postgres -w -c "select * from persons"
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
```
