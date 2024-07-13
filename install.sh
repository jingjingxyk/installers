#!/usr/bin/env bash

__DIR__=$(cd "$(dirname "$0")";pwd)
set -x

PHP=$(which php)
PHPIZE=$(which phpize)
PHP_CONFIG=$(which php-config)


if  test -x "${PHP}" -a  -x "${PHPIZE}" -a  -x  "${PHP_CONFIG}"  ; then
  ${PHP} -v
  ${PHPIZE} --help
  ${PHP_CONFIG} --help
else
  echo 'no found PHP '
  exit 0
fi



mkdir -p /tmp/build

# shellcheck disable=SC2164
cd /tmp/build/


MIRROR=''
DEBUG=0
ENABLE_TEST=0
VERSION_LATEST=0
SWOOLE_VERSION=''
PHPY_VERSION=''

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
  --swoole-version)
    SWOOLE_VERSION='master'
    ;;
  --phpy-version)
    PHPY_VERSION='main'
    ;;
  --test)
     ENABLE_TEST=1
     ;;
  --*)
    echo "no found mirror option $1"
    ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

# 保持源码最新
test $VERSION_LATEST -eq 1 && test -d swoole-src && rm -rf swoole-src


case "$MIRROR" in
china )
  test -d swoole-src || git clone -b master --single-branch --depth=1 https://gitee.com/swoole/swoole.git swoole-src
  ;;
*)
  test -d swoole-src || git clone -b master --single-branch --depth=1 https://github.com/swoole/swoole-src.git
  ;;
esac


SWOOLE_ODBC_OPTIONS="--with-swoole-odbc=unixODBC,/usr"
SWOOLE_IO_URING=''
SWOOLE_DEBUG_OPTIONS='';
SWOOLE_THREAD_OPTION='';

if [ $DEBUG -eq 1 ] ;then
  SWOOLE_DEBUG_OPTIONS=' --enable-debug --enable-debug-log --enable-trace-log '
fi

# shellcheck disable=SC2046
if [ $(php -r "echo PHP_ZTS;") -eq 1 ] ; then
  SWOOLE_THREAD_OPTION="--enable-swoole-thread"
fi

CPU_LOGICAL_PROCESSORS=4
OS=$(uname -s)
ARCH=$(uname -m)
case "$OS" in
Darwin)
  CPU_LOGICAL_PROCESSORS=$(sysctl -n hw.ncpu)
  case "$ARCH" in
    x86_64)
        export PKG_CONFIG_PATH=/usr/local/opt/libpq/lib/pkgconfig/:/usr/local/opt/unixodbc/lib/pkgconfig/
        SWOOLE_ODBC_OPTIONS="--with-swoole-odbc=unixODBC,/usr/local/opt/unixodbc/"
      ;;
    arm64)
        export PKG_CONFIG_PATH=/opt/homebrew/opt/libpq/lib/pkgconfig/:/opt/homebrew/opt/unixodbc/lib/pkgconfig/
        SWOOLE_ODBC_OPTIONS="--with-swoole-odbc=unixODBC,/opt/homebrew/opt/unixodbc/"
      ;;
  esac
  ;;
Linux)
  CPU_LOGICAL_PROCESSORS=$(grep "processor" /proc/cpuinfo | sort -u | wc -l)
  OS_RELEASE=$(awk -F= '/^ID=/{print $2}' /etc/os-release |tr -d '\n' | tr -d '\"')
  case "$OS_RELEASE" in
    'rocky' | 'almalinux'  ) # | 'rhel' |  'centos' | 'fedora'  # 未测试
      SWOOLE_ODBC_OPTIONS="" # 缺少 unixODBC-devel
      ;;
    'debian' | 'ubuntu'  ) # | 'alpine' # 构建报错
      SWOOLE_IO_URING=' --enable-iouring '
      ;;
  esac
  ;;
*)
  ;;
esac



cd swoole-src

test -f ext-src/.libs/php_swoole.o && make clean

phpize

./configure \
${SWOOLE_DEBUG_OPTIONS}  \
--enable-openssl \
--enable-sockets \
--enable-mysqlnd \
--enable-cares \
--enable-swoole-curl \
--enable-swoole-pgsql \
--enable-swoole-sqlite \
${SWOOLE_ODBC_OPTIONS} \
${SWOOLE_IO_URING} \
${SWOOLE_THREAD_OPTION} \

if [ $? -ne 0 ] ; then
    echo $?
    exit 0
fi

# --with-php-config=/usr/bin/php-config
# --enable-swoole-thread  \
# --enable-iouring


make  -j ${CPU_LOGICAL_PROCESSORS}

if [ $? -ne 0 ] ; then
    echo $?
    exit 0
fi

if test $ENABLE_TEST -eq 1 ; then
  cd /tmp/build/swoole-src/tests/include/lib/
  composer install
  cd /tmp/build/swoole-src/
  make test
fi

make install
if [ $? -ne 0 ] ; then
    echo $?
    exit 0
fi


# 创建 swoole.ini

PHP_INI_SCAN_DIR=$(php --ini | grep  "Scan for additional .ini files in:" | awk -F 'in:' '{ print $2 }' | xargs)
if [ $? -ne 0 ] ; then
    echo $?
    exit 0
fi

if [ -n "${PHP_INI_SCAN_DIR}" ] && [ -d "${PHP_INI_SCAN_DIR}" ]; then
  SUDO=''
  if [ ! -w "${PHP_INI_SCAN_DIR}" ] ; then
    SUDO='sudo'
  fi

  ${SUDO} tee  ${PHP_INI_SCAN_DIR}/90-swoole.ini << EOF
extension=swoole.so
swoole.use_shortname=On
EOF

fi

php -v
php --ini
php --ini | grep  ".ini files"
php --ri swoole
