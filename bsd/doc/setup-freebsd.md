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
service sshd restart
```

## 扩容 rootfs

```
service growfs onestart
```

## 配置交换分区

- 默认没有配置 swap 分区
- 创建交换文件（以 2GB 为例），启用交换文件

```
dd if=/dev/zero of=/swapfile bs=1M count=4096
chmod 600 /swapfile
mdconfig -a -t vnode -f /swapfile -u 0 && swapon /dev/md0
swapinfo
```

- 配置开机自动挂载，编辑 /etc/fstab，添加以下行

```
md99    none    swap    sw,file=/swapfile,late  0       0
```

## 安装软件

```
export http_proxy="http://192.168.00.129:7890"
export https_proxy="http://192.168.00.129:7890"
```

```
pkg update -f
pkg install -y fastfetch nano llvm15 git python3 usbutils pciutils lscpu lsblk wget
```

![freebsd_pkg](./figs/freebsd_pkg.png)

## 本地构建替换内核

- 系统启动并联网后，可以尝试在 FreeBSD 本地编译内核进行开发

```
cd /usr/src
git init
git remote add origin https://gitlab.com/FreeBSD/freebsd-src.git
git fetch --depth 1 origin release/14.3.0
git checkout FETCH_HEAD
```

- 设置编译内核的工具

```
# LLVM 工具的路径按照实际情况设置
export PATH=/usr/local/bin:$PATH
export CC=/usr/local/bin/clang15
export CXX=/usr/local/bin/clang++15
export LD=/usr/local/bin/ld.lld15
export CPP=/usr/local/bin/clang-cpp15
export HOSTCC=/usr/local/bin/clang15
export HOSTCXX=/usr/local/bin/clang++15
export LLVM_CONFIG=/usr/local/bin/llvm-config15
```

```
cd /usr/src
DEBUG_FLAGS="-g -Og" make kernel-toolchain buildkernel buildworld KERNCONF=GENERIC -j4
```

- 编译内核

```
cd /usr/src
DEBUG_FLAGS="-g -Og" make kernel-toolchain KERNCONF=GENERIC -j4
DEBUG_FLAGS="-g -Og" make buildkernel KERNCONF=GENERIC -j4
```

- 编译用户态

```
DEBUG_FLAGS="-g -Og" make buildworld -j4
```

- 编译具体的 ko 文件，如设备树 dtb 和 rtw89 驱动

```
# 编译设备树
cd /usr/src/sys/modules/dtb/rockchip
DEBUG_FLAGS="-g -Og" make -j4
DEBUG_FLAGS="-g -Og" make install
ls -lh /boot/dtb

# 编译 ko 模块
cd /usr/src/sys/modules/rtw89
DEBUG_FLAGS="-g -Og" make -j4
DEBUG_FLAGS="-g -Og" make install
ls -lh /boot/modules/if_rtw89.ko
```

- 如果需要的话可以编译 EFI 启动器

```
cd /usr/src/stand
DEBUG_FLAGS="-g -Og" make clean
DEBUG_FLAGS="-g -Og" make
mkdir -p /usr/output
DEBUG_FLAGS="-g -Og" make DESTDIR=/usr/output install
```

- 安装系统内核然后重启

```
vi /boot/loader.conf
# 添加下面的配置
kernel="kernel GENERIC"

# 安装用户态，一般是不需要的
DEBUG_FLAGS="-g -Og" make installworld

ls -l /boot/kernel/kernel*
DEBUG_FLAGS="-g -Og" make installkernel KERNCONF=GENERIC
ls -l /boot/kernel/kernel*
sync
poweroff
```

- 启动完成后可以查看信息变化

```
uname -a
```


## 本地构建应用程序

- 参考[FreeBSD Ports and Packages: What you need to know](https://freebsdfoundation.org/blog/freebsd-ports-and-packages-what-you-need-to-know/)

- 下载 FreeBSD ports

```
mkdir -p /usr/ports
cd /usr/ports
git init .
git remote add origin https://git.freebsd.org/ports.git
git fetch --depth 1 origin release/14.3.0
git checkout FETCH_HEAD
```

- 配置特定的应用程序 ports，以 unixbench 为例

```
# LLVM 工具的路径按照实际情况设置
export PATH=/usr/local/bin:$PATH
export CC=/usr/local/bin/clang15
export CXX=/usr/local/bin/clang++15
export LD=/usr/local/bin/ld.lld15
export CPP=/usr/local/bin/clang-cpp15
export HOSTCC=/usr/local/bin/clang15
export HOSTCXX=/usr/local/bin/clang++15
export LLVM_CONFIG=/usr/local/bin/llvm-config15

cd /usr/ports/benchmarks/unixbench/
# 参考前面的内容，配置 export CC= 等编译工具
make config
make package
```

- 编译完成后可以直接使用刚刚编译出来的 unixbench 了

```
ls /usr/ports/benchmarks/unixbench/work/pkg
pkg add /usr/ports/benchmarks/unixbench/work/pkg/unixbench-<version>.txz

unixbench --version
```

## 使用 crochet 构建镜像

> 使用 root 用户进行编译，编译前确保 freebsd 源码下载到 /usr/src 目录下
```
# LLVM 工具的路径按照实际情况设置
export PATH=/usr/local/bin:$PATH
export CC=/usr/local/bin/clang15
export CXX=/usr/local/bin/clang++15
export LD=/usr/local/bin/ld.lld15
export CPP=/usr/local/bin/clang-cpp15
export HOSTCC=/usr/local/bin/clang15
export HOSTCXX=/usr/local/bin/clang++15
export LLVM_CONFIG=/usr/local/bin/llvm-config15

git clone https://github.com/freebsd/crochet.git
cd crochet
pkg install u-boot-nanopi-r4s
export IMAGE_SIZE=4096
/bin/sh crochet.sh -b NanoPi-R4S -v
```