#!/usr/bin/env bash

__DIR__=$(
  cd "$(dirname "$0")"
  pwd
)
set -x

OS=$(uname -s)
ARCH=$(uname -m)
if [ "$OS" = 'Linux' ]; then
  if [ ! "$BASH_VERSION" ]; then
    echo "Please  use bash to run this script ($0) " 1>&2
    exit 1
  fi
fi

CPU_LOGICAL_PROCESSORS=4
MIRROR='' # phpy 源码镜像源
DEBUG=0
ENABLE_TEST=0
VERSION_LATEST=0    # 保持源码最新，每次执行都需要下载源码
X_PHPY_VERSION=''   # 指定  phpy 版本
PHPY_VERSION='main' # 默认 phpy 版本
PHP_VERSION=''      # PHP 版本
PHP_CONFIG=''       # php-config 所在位置
PYTHON_DIR=''       # python 所在目录
PYTHON_VERSION=''   # python 版本
PYTHON_CONFIG=''    # python-config 文件位置

while [ $# -gt 0 ]; do
  case "$1" in
  --mirror)
    MIRROR="$2"
    ;;
  --latest)
    VERSION_LATEST=1
    ;;
  --phpy-version)
    X_PHPY_VERSION="$2"
    ;;
  --test)
    ENABLE_TEST=1
    ;;
  --with-python-dir)
    PYTHON_DIR="$2"
    ;;
  --with-python-config)
    PYTHON_CONFIG="$2"
    ;;
  --with-python-version)
    PYTHON_VERSION="$2"
    ;;
  --*)
    echo "no found  option $1"
    ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

check_php_exists() {
  PHP=$(which php)
  PHPIZE=$(which phpize)
  PHP_CONFIG=$(which php-config)

  if test -x "${PHP}" -a -x "${PHPIZE}" -a -x "${PHP_CONFIG}"; then
    ${PHP} -v
    ${PHPIZE} --help
    ${PHP_CONFIG} --help
    PHP_VERSION=$($(which php-config) --vernum)
    PYTHON_DIR=$(python3-config --prefix)
    PYTHON_VERSION="$(python3 -V | awk '{ print $2 }')"
    PYTHON_CONFIG=$(which python3-config)
    return 1
  else
    return 0
  fi
}

install_phpy() {

  if test -n "${X_PHPY_VERSION}"; then
    PHPY_VERSION="${X_PHPY_VERSION}"
  fi

  #  80000
  if test $((PHP_VERSION)) -lt 70200; then
    echo 'no support this php version'
    exit 0
  fi

  mkdir -p /tmp/build
  # shellcheck disable=SC2164
  cd /tmp/build/

  # 指定 phpy 版本 和 已经存在的 phpy 版本不一致
  if test -n "${X_PHPY_VERSION}" -a -d phpy/; then
    if test -f phpy/x-phpy-version; then
      if test "$(cat phpy/x-phpy-version)" != "${X_PHPY_VERSION}"; then
        test -d phpy && rm -rf phpy
      fi
    else
      test -d phpy && rm -rf phpy
    fi
  fi

  # 保持源码最新
  test $VERSION_LATEST -eq 1 && test -d phpy && rm -rf phpy

  case "$MIRROR" in
  china)
    test -d phpy || git clone -b $PHPY_VERSION --single-branch --depth=1 https://gitee.com/swoole/phpy.git
    ;;
  *)
    test -d phpy || git clone -b $PHPY_VERSION --single-branch --depth=1 https://gitee.com/swoole/phpy.git
    ;;
  esac
  if [ $? -ne 0 ]; then
    echo $?
    exit 3
  fi
  echo $PHPY_VERSION >phpy/x-phpy-version

  case "$OS" in
  Darwin)
    CPU_LOGICAL_PROCESSORS=$(sysctl -n hw.ncpu)
    ;;
  Linux)
    CPU_LOGICAL_PROCESSORS=$(grep "processor" /proc/cpuinfo | sort -u | wc -l)
    ;;
  *) ;;
  esac

  cd /tmp/build/phpy

  test -f ext-src/.libs/php_swoole.o && make clean

  phpize

  ./configure --help

  ./configure \
    --with-php-config="${PHP_CONFIG}" \
    --with-python-dir="${PYTHON_DIR}" \
    --with-python-config="${PYTHON_CONFIG}" \
    --with-python-version="${PYTHON_VERSION}"

  if [ $? -ne 0 ]; then
    echo $?
    exit 3
  fi

  make -j ${CPU_LOGICAL_PROCESSORS}

  if [ $? -ne 0 ]; then
    echo $?
    exit 3
  fi

  if test $ENABLE_TEST -eq 1; then
    cd /tmp/build/phpy/tests/include/lib/
    composer install
    cd /tmp/build/phpy/
    make test
  fi

  make install
  if [ $? -ne 0 ]; then
    echo $?
    exit 3
  fi

  # 创建 swoole.ini

  PHP_INI_SCAN_DIR=$(php --ini | grep "Scan for additional .ini files in:" | awk -F 'in:' '{ print $2 }' | xargs)
  if [ $? -ne 0 ]; then
    echo $?
    exit 3
  fi

  if [ -n "${PHP_INI_SCAN_DIR}" ] && [ -d "${PHP_INI_SCAN_DIR}" ]; then
    SUDO=''
    if [ ! -w "${PHP_INI_SCAN_DIR}" ]; then
      SUDO='sudo'
    fi

    ${SUDO} tee ${PHP_INI_SCAN_DIR}/91-phpy.ini <<EOF
extension=phpy.so
swoole.use_shortname=On
EOF

  fi

  php -v
  php -m
  php --ini
  php --ini | grep ".ini files"
  php --ri phpy
}

install() {
  check_php_exists
  if [ $? -eq 1 ]; then
    install_phpy
  else
    echo 'no found PHP IN $PATH '
  fi
}

# 安装 入口
install

##  --with-python-dir=/opt/anaconda3  -with-python-config=/opt/anaconda3/bin/python3-config --with-python-version=3.12
