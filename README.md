# Swoole Installer

一行命令给PHP安装上 swoole 扩展

## [配置选项文档](docs/options.md)

## 用法

From https://www.swoole.com:

```bash

curl -fsSL  https://github.com/swoole/installers/blob/main/install.sh?raw=true | bash -s -- --latest --swoole-version=v5.1.3

```

From https://github.com/swoole/installers:

```bash

curl -fsSL  https://github.com/swoole/installers/blob/main/install.sh?raw=true | bash -s -- --mirror china --latest

```

From https://gitee.com/jingjingxyk/swoole-install:

```bash

curl -fsSL  https://gitee.com/jingjingxyk/swoole-install/raw/main/install.sh | bash -s -- --mirror china --latest

# 使用系统包管理工具安装 php
curl -fsSL  https://gitee.com/jingjingxyk/swoole-install/raw/main/install.sh | bash -s -- --mirror china --latest --install-php

```

## 可能遇到的的问题

### $PATH 环境变量中 未检测到 php phpize php-config

通过临时修改 $PATH 环境变量,例子：
` export PATH=your-php-install-dir/bin/:$PATH `

### alpine 环境运行本脚本需要bash

> 第一次用 sh 执行脚本
> 第二次用 bash 执行脚本

```bash
  sh install.sh
  bash install.sh
```

## 支持的操作系统

| 操作系统                                                         | 支持情况 |
|--------------------------------------------------------------|------|
| [debian](https://www.debian.org/)                            | ✅    |
| [ubuntu](https://ubuntu.com/)                                | ✅    |
| [rockylinux](https://rockylinux.org/)                        | ✅    |
| [almalinux](https://almalinux.org/)                          | ✅    |
| [Alibaba cloud liunx](https://www.aliyun.com/product/alinux) | ✅    |
| [anolis](https://openanolis.cn/anolisos)                     | ✅    |
| [fedora ](https://fedoraproject.org/)                        | ✅    |
| [alpine](https://www.alpinelinux.org/)                       | ✅    |
| [kali](https://www.kali.org/)                                | ✅    |
| [macos](https://www.apple.com/)                              | ✅    |
| wsl                                                          |      |
| FreeBSD 13                                                   |      |
| [OpenEuler](https://www.openeuler.org/)                      | ✅    |
| Huawei Cloud EulerOS                                         | ✅    |
| [archlinux](https://archlinux.org/)                          | ✅    |
