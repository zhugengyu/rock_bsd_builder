
- 启动 Firefly

```
fatload scsi 0:1 0x90000000 firefly_v2.dtb; fatload scsi 0:1 0x90100000 Image; booti 0x90100000 - 0x90000000; 
```

- 临时设置 IP

```
ip addr flush dev eth0
ip addr add 10.31.94.219/24 dev eth0
ip link set eth0 up
ip route add default via 10.31.94.254
bash -c 'echo "nameserver 10.22.0.16" > /etc/resolv.conf'
bash -c 'echo "nameserver 114.114.114.114" >> /etc/resolv.conf'
```

- 永久设置固定 IP
> /etc/netplan/01-network-manager-all.yaml

```
auto eth0
iface eth0 inet static
    address 10.31.94.219
    netmask 255.255.255.0
    gateway 10.31.94.254
```

- 安装软件

```
sudo apt update
sudo apt install build-essential libncurses-dev bison flex libssl-dev libelf-dev bc git
sudo apt install usbutils pciutils
sudo apt install neofetch
sudo apt install cpufrequtils
```