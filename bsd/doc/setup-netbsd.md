## SSH 连接

- 允许 root 登录
```
vi /etc/ssh/sshd_config
# 允许 root 登录
PermitRootLogin yes
```

- 设置密码
```
passwd
```

- 重启 SSH
```
/etc/rc.d/sshd restart
```

## 安装软件

```
export http_proxy="http://192.168.00.129:7890"
export https_proxy="http://192.168.00.129:7890"
```

```
export PATH="/usr/pkg/sbin:/usr/pkg/bin:$PATH"
export PKG_PATH="https://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/aarch64/9.0_2025Q2/All/"
export SSL_NO_VERIFY_PEER=1
export SSL_NO_VERIFY_HOSTNAME=1
pkg_add pkgin
```


```
pkgin update
pkgin install neofetch pciutils nano
pkgin install gcc10 gmake binutils flex bison cwrappers git
pkgin search u-boot
pkgin install u-boot-rockpro64-2022.01
```