
- https://vermaden.wordpress.com/2023/08/18/freebsd-bhyve-virtualization/
- https://freebsdfoundation.org/our-work/journal/browser-based-edition/virtualization-2/bhyve-for-the-linux-and-windows-users/
- https://freebsdfoundation.org/project/gui-for-managing-bhyve-hypervisor-on-freebsd/


- 查看是否支持 POPCNT 特性
```
dmesg | grep Features2
```

- 安装依赖
```
pkg install -y openntpd vm-bhyve bhyve-firmware
```

```
zfs create -o mountpoint=/vm -o recordsize=64k zroot/vm

cat <<EOF >> /etc/rc.conf
vm_enable="YES"
vm_dir="zfs:zroot/vm"
vm_list=""
vm_delay="30"
EOF

vm init
```

```
vm iso https://repo.almalinux.org/almalinux/9.5/isos/x86_64/AlmaLinux-9.5-x86_64-dvd.iso
```