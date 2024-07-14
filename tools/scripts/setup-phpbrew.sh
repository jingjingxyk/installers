#!/usr/bin/env bash

set -exu
__DIR__=$(
  cd "$(dirname "$0")"
  pwd
)
__PROJECT__=$(
  cd ${__DIR__}/../../
  pwd
)
cd ${__DIR__}


test -d ${__PROJECT__}/var/ || mkdir -p ${__PROJECT__}/var/

cd ${__PROJECT__}/var/

while [ $# -gt 0 ]; do
  case "$1" in
  --proxy)
    export HTTP_PROXY="$2"
    export HTTPS_PROXY="$2"
    NO_PROXY="127.0.0.0/8,10.0.0.0/8,100.64.0.0/10,172.16.0.0/12,192.168.0.0/16"
    NO_PROXY="${NO_PROXY},::1/128,fe80::/10,fd00::/8,ff00::/8"
    NO_PROXY="${NO_PROXY},localhost"
    export NO_PROXY="${NO_PROXY},.gitee.com,.swoole.com"
    ;;
  --latest)
    test -f phpbrew.phar && rm -f phpbrew.phar
    ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

test -f phpbrew.phar || curl -L -O https://github.com/phpbrew/phpbrew/releases/latest/download/phpbrew.phar
test -x phpbrew.phar || chmod +x phpbrew.phar
php phpbrew.phar --help
sudo mv phpbrew.phar /usr/local/bin/phpbrew
