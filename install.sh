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
MIRROR='' # swoole 源码镜像源
DEBUG=0
ENABLE_TEST=0
VERSION_LATEST=0        # 保持源码最新，每次执行都需要下载源码
X_SWOOLE_VERSION=''     # 指定 swoole 版本
SWOOLE_VERSION='master' # 默认 swoole 版本
INSTALL_PHP=0           # 0 未知，待检测 、1 系统已安装PHP、2 系统未安装PHP
FORCE_INSTALL_PHP=0     # 0 未设置、3 要求安装PHP

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
    X_SWOOLE_VERSION="$2"
    ;;
  --test)
    ENABLE_TEST=1
    ;;
  --install-php)
    if [ "$2" == "1" ]; then
      FORCE_INSTALL_PHP=3
    fi
    ;;
  --*)
    echo "no found mirror option $1"
    ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

check_environment() {
  PHP=$(which php)
  PHPIZE=$(which phpize)
  PHP_CONFIG=$(which php-config)

  if test -x "${PHP}" -a -x "${PHPIZE}" -a -x "${PHP_CONFIG}"; then
    ${PHP} -v
    ${PHPIZE} --help
    ${PHP_CONFIG} --help
    INSTALL_PHP=1
  else
    INSTALL_PHP=2
    echo 'no found PHP IN $PATH '
    if test ${FORCE_INSTALL_PHP} -ne 3; then
      # 未发现 php ，也不需要自动安装 PHP
      exit 0
    fi
  fi
}

install_swoole_dependencies() {
  case "$OS" in
  Darwin | darwin)
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_INSTALL_FROM_API=1
    brew install wget curl libtool automake re2c llvm flex bison
    brew install libtool gettext coreutils pkg-config cmake
    brew install c-ares libpq unixodbc brotli curl pcre2
    ;;
  Linux)
    OS_RELEASE=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '\n' | tr -d '\"')
    case "$OS_RELEASE" in
    'rocky' | 'almalinux' | 'alinux' | 'anolis' | 'fedora')
      yum update -y
      { yum install -y curl ; } || { echo $? ; }
      { yum install -y curl-minimal ; } || { echo $? ; }
      yum install -y curl-minimal
      yum install -y git wget  ca-certificates
      yum install -y autoconf automake libtool cmake bison gettext zip unzip xz
      yum install -y pkg-config bzip2 flex which
      yum install -y c-ares-devel libcurl-devel pcre-devel postgresql-devel unixODBC brotli-devel sqlite-devel openssl-devel

      ;;
    'debian' | 'ubuntu')
      export DEBIAN_FRONTEND=noninteractive
      export TZ="Etc/UTC"
      ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
      apt update -y
      apt install -y git curl wget ca-certificates
      apt install -y xz-utils autoconf automake libtool cmake bison re2c gettext coreutils lzip zip unzip
      apt install -y pkg-config bzip2 flex p7zip

      apt install -y gcc g++ libtool-bin autopoint
      apt install -y linux-headers-generic

      apt-get install -y libc-ares-dev libcurl4-openssl-dev
      apt-get install -y libpcre3 libpcre3-dev libpq-dev libsqlite3-dev unixodbc-dev
      apt-get install -y libbrotli-dev liburing-dev

      ;;
    'alpine')
      apk update
      apk add autoconf automake make libtool cmake bison re2c gcc g++ git curl wget pkgconf ca-certificates
      apk add clang-dev clang lld alpine-sdk xz autoconf automake tar gzip zip unzip bzip2
      apk add curl-dev c-ares-dev postgresql-dev sqlite-dev unixodbc-dev liburing-dev linux-headers

      ;;
    esac
    ;;
  *)
    case "$(uname -r)" in
    *microsoft* | *Microsoft*)
      # WSL
      ;;
    esac
    ;;
  esac
}

install_php() {
  case "$OS" in
  Darwin | darwin)
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_INSTALL_FROM_API=1
    brew install php
    ;;
  Linux)
    OS_RELEASE=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '\n' | tr -d '\"')
    case "$OS_RELEASE" in
    'rocky' | 'almalinux' | 'alinux' | 'anolis' | 'fedora')
      yum update -y
      yum install -y php-cli php-pear php-devel php-curl php-intl php-json
      yum install -y php-mbstring php-tokenizer php-xml
      yum install -y php-pdo php-mysqlnd
      ;;
    'debian' | 'ubuntu')
      export DEBIAN_FRONTEND=noninteractive
      export TZ="Etc/UTC"
      ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
      apt update -y
      apt install -y php-cli php-pear php-dev php-curl php-intl
      apt install -y php-mbstring php-tokenizer php-xml
      apt install -y php-mysqlnd php-pgsql php-sqlite3 php-redis php-mongodb
      ;;
    'alpine')
      apk update
      apk add php82-cli php82-dev
      apk add php82-iconv php82-mbstring php82-phar php82-openssl
      apk add php82-posix php82-tokenizer php82-intl
      apk add php82-dom php82-xmlwriter php82-xml php82-simplexml
      apk add php82-pdo php82-sockets php82-curl php82-mysqlnd php82-pgsql php82-sqlite3
      apk add php82-redis php82-mongodb

      php82 -v
      php82 --ini
      php82 --ini | grep ".ini files"

      ln -sf /usr/bin/php82 /usr/bin/php
      ln -sf /usr/bin/phpize82 /usr/bin/phpize
      ln -sf /usr/bin/php-config82 /usr/bin/php-config

      ;;
    esac
    ;;
  *)
    case "$(uname -r)" in
    *microsoft* | *Microsoft*)
      # WSL
      ;;
    esac
    ;;
  esac

  which php
  which phpize
  which php-config
  php-config --help
}

install_swoole() {
  local SWOOLE_OPTIONS=''

  # shellcheck disable=SC2155
  local PHP_VERSION=$($(which php-config) --vernum)

  if test -n "${X_SWOOLE_VERSION}"; then
    SWOOLE_VERSION="${X_SWOOLE_VERSION}"
  fi

  if test $((PHP_VERSION)) -ge 80000 -a $((PHP_VERSION)) -ge 80100; then
    test -z "${X_SWOOLE_VERSION}" && SWOOLE_VERSION="v5.1.3"
    test ${VERSION_LATEST} -eq 1 && SWOOLE_VERSION="5.1.x"
  fi

  if test $((PHP_VERSION)) -ge 70200 -a $((PHP_VERSION)) -lt 80000; then
    test -z "${X_SWOOLE_VERSION}" && SWOOLE_VERSION="v4.8.13"
    test ${VERSION_LATEST} -eq 1 && SWOOLE_VERSION="4.8.x"
    SWOOLE_OPTIONS=' --enable-swoole-json --enable-http2 '
  fi

  if test $((PHP_VERSION)) -lt 70200; then
    echo 'no support this php version'
    exit 0
  fi

  install_swoole_dependencies

  mkdir -p /tmp/build
  # shellcheck disable=SC2164
  cd /tmp/build/

  # 指定swoole版本 和 已经存在的版本不一致
  if test -n "${X_SWOOLE_VERSION}" -a -d swoole-src/; then
    if test -f swoole-src/x-swoole-version; then
      if test "$(cat swoole-src/x-swoole-version)" != "${X_SWOOLE_VERSION}"; then
        test -d swoole-src && rm -rf swoole-src
      fi
    else
      test -d swoole-src && rm -rf swoole-src
    fi
  fi

  # 保持源码最新
  test $VERSION_LATEST -eq 1 && test -d swoole-src && rm -rf swoole-src

  case "$MIRROR" in
  china)
    test -d swoole-src || git clone -b $SWOOLE_VERSION --single-branch --depth=1 https://gitee.com/swoole/swoole.git swoole-src
    ;;
  *)
    test -d swoole-src || git clone -b $SWOOLE_VERSION --single-branch --depth=1 https://github.com/swoole/swoole-src.git
    ;;
  esac
  if [ $? -ne 0 ]; then
    echo $?
    exit 0
  fi

  echo $SWOOLE_VERSION >swoole-src/x-swoole-version

  SWOOLE_ODBC_OPTIONS=""
  SWOOLE_IO_URING=''
  SWOOLE_DEBUG_OPTIONS=''
  SWOOLE_THREAD_OPTION=''

  if [ $DEBUG -eq 1 ]; then
    SWOOLE_DEBUG_OPTIONS=' --enable-debug --enable-debug-log --enable-trace-log '
  fi

  # shellcheck disable=SC2046
  if [ $(php -r "echo PHP_ZTS;") -eq 1 ]; then
    SWOOLE_THREAD_OPTION="--enable-swoole-thread"
  fi

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
      # /opt/homebrew/opt/pcre2/lib/pkgconfig
      # export PATH=/opt/homebrew/opt/pcre2/bin/:$PATH
      php-config --prefix
      ln -s /opt/homebrew/opt/pcre2/include/pcre2.h $(php-config --prefix)/include/php/ext/pcre/pcre2.h

      SWOOLE_ODBC_OPTIONS="--with-swoole-odbc=unixODBC,/opt/homebrew/opt/unixodbc/"
      ;;
    esac
    ;;
  Linux)
    CPU_LOGICAL_PROCESSORS=$(grep "processor" /proc/cpuinfo | sort -u | wc -l)
    OS_RELEASE=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '\n' | tr -d '\"')
    case "$OS_RELEASE" in
    'rocky' | 'almalinux' | 'alinux' | 'anolis' | 'fedora') # | 'rhel' |  'centos'  # 未测试
      SWOOLE_ODBC_OPTIONS=""                                # 缺少 unixODBC-devel
      ;;
    'debian' | 'ubuntu') # | 'alpine' # 构建 iouring 报错
      SWOOLE_IO_URING=' --enable-iouring '
      SWOOLE_ODBC_OPTIONS="--with-swoole-odbc=unixODBC,/usr"
      ;;
    esac
    ;;
  *) ;;

  esac

  cd /tmp/build/swoole-src

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
  check_environment
  if test ${INSTALL_PHP} -eq 2 -a ${FORCE_INSTALL_PHP} -eq 3; then
    # 系统未安装PHP ，指定要求安装PHP
    install_php
    if test -x "$(which php)"; then
      echo 'INSTALL PHP SUCCESS '
      $(which php) -v
    else
      echo 'no found PHP in $PATH'
      echo 'please reinstall PHP '
      exit 0
    fi
  fi

  install_swoole

}

# 安装 入口
install
