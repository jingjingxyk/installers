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
VERSION_LATEST=0        # 保持源码最新，每次执行都需要下载源码
X_PHPY_VERSION=''     # 指定  phpy 版本
PHPY_VERSION='main' # 默认 phpy 版本
PHP_VERSION=''  # PHP 版本


while [ $# -gt 0 ]; do
  case "$1" in
  --mirror)
    MIRROR="$2"
    ;;
  --debug)
    DEBUG=1
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
        test -d swoole-src && rm -rf swoole-src
      fi
    else
      test -d swoole-src && rm -rf swoole-src
    fi
  fi

  # 保持源码最新
  test $VERSION_LATEST -eq 1 && test -d phpy && rm -rf phpy

  case "$MIRROR" in
  china)
    test -d phpy || git clone -b $PHPY_VERSION --single-branch --depth=1 https://gitee.com/swoole/phpy.git swoole-src
    ;;
  *)
    test -d phpy || git clone -b $PHPY_VERSION --single-branch --depth=1 https://gitee.com/swoole/phpy.git
    ;;
  esac
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
    ${SWOOLE_DEBUG_OPTIONS} \
    --enable-openssl \
    --enable-sockets \
    --enable-mysqlnd \
    --enable-cares \
    --enable-swoole-curl \
    ${SWOOLE_OPTIONS} \
    --enable-swoole-pgsql \
    --enable-swoole-sqlite \
    ${SWOOLE_ODBC_OPTIONS} \
    ${SWOOLE_IO_URING} \
    ${SWOOLE_THREAD_OPTION}

  if [ $? -ne 0 ]; then
    echo $?
    exit 0
  fi

  # --with-php-config=/usr/bin/php-config
  # --enable-swoole-thread  \
  # --enable-iouring

  make -j ${CPU_LOGICAL_PROCESSORS}

  if [ $? -ne 0 ]; then
    echo $?
    exit 0
  fi

  if test $ENABLE_TEST -eq 1; then
    cd /tmp/build/swoole-src/tests/include/lib/
    composer install
    cd /tmp/build/swoole-src/
    make test
  fi

  make install
  if [ $? -ne 0 ]; then
    echo $?
    exit 0
  fi

  # 创建 swoole.ini

  PHP_INI_SCAN_DIR=$(php --ini | grep "Scan for additional .ini files in:" | awk -F 'in:' '{ print $2 }' | xargs)
  if [ $? -ne 0 ]; then
    echo $?
    exit 0
  fi

  if [ -n "${PHP_INI_SCAN_DIR}" ] && [ -d "${PHP_INI_SCAN_DIR}" ]; then
    SUDO=''
    if [ ! -w "${PHP_INI_SCAN_DIR}" ]; then
      SUDO='sudo'
    fi

    ${SUDO} tee ${PHP_INI_SCAN_DIR}/90-swoole.ini <<EOF
extension=swoole.so
swoole.use_shortname=On
EOF

  fi

  php -v
  php --ini
  php --ini | grep ".ini files"
  php --ri swoole
}

install() {
  if test check_php_exists -eq 1 ; then
     install_phpy
  else
      echo 'no found PHP IN $PATH '
  fi
}

# 安装 入口
install
