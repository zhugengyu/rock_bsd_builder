## mk-kernel.sh

> mk-kernel.sh tb-rk3399prod

- 设备树，内核版本 > 4.5，使用主线 DTB，如 rk3399-rock-pi-4.dtb.dts, 否则使用 RK 分支的设备树，如 rk3399pro-toybrick-prod-linux.dts，生成路径 kernel/arch/arm64/boot/dts/rockchip
- 内核，生成路径 kernel/arch/arm64/boot/Image
- 使用 extlinux, ${EXTLINUXPATH}/${CHIP}.conf 如 rk3399pro.conf

## mk-image.sh

> mk-image.sh -c rk3399pro -t system -r rootfs.img

- 准备分区
LOADER1: 通常包含 U-Boot SPL (Secondary Program Loader)
LOADER2: 主 U-Boot 引导程序
ATF: ARM Trusted Firmware，安全监控代码
BOOT: 存放内核镜像、设备树、extlinux 配置等
ROOTFS: 根文件系统（EXT4、F2FS 等格式）
```
0       ┌─────────────────┐
        │    SYSTEM        │ 32 KB
64      ├─────────────────┤
        │    LOADER1       │ 3.9 MB
8064    ├─────────────────┤
        │   RESERVED1      │ 64 KB
8192    ├─────────────────┤
        │   RESERVED2      │ 4 MB
16384   ├─────────────────┤
        │    LOADER2       │ 4 MB
24576   ├─────────────────┤
        │      ATF         │ 4 MB
32768   ├─────────────────┤
        │     BOOT         │ 512 MB
1081344 ├─────────────────┤
        │    ROOTFS        │ 剩余空间
        └─────────────────┘
```

- 生成 boot.img（Linux 启动镜像）和 system.img（系统镜像）

```
boot.img (FAT32)
├── extlinux/
│   └── extlinux.conf    # 启动配置文件
├── overlays/            # 仅RockPi4系列
│   └── *.dtbo          # 设备树覆盖文件
├── Image               # 内核镜像(ARM64)
├── zImage              # 内核镜像(ARM32)  
└── *.dtb               # 设备树文件
```

```
system.img (完整磁盘镜像)
├── GPT分区表
├── loader1分区    (U-Boot SPL)      - 起始扇区: 64
├── loader2分区    (主U-Boot)        - 起始扇区: 16,384  
├── trust分区      (ATF固件)         - 起始扇区: 24,576
├── boot分区       (FAT32启动分区)   - 起始扇区: 32,768
└── rootfs分区     (根文件系统)      - 起始扇区: 1,081,344
```

- 将 boot.img 和 rootfs.img 嵌入到 system.img 中

```
# burn boot image (16MB位置)
dd if=${OUT}/boot.img of=${SYSTEM} conv=notrunc seek=${BOOT_START}

# burn rootfs image (528MB位置)
dd if=${ROOTFS_PATH} of=${SYSTEM} conv=notrunc,fsync seek=${ROOTFS_START}
```