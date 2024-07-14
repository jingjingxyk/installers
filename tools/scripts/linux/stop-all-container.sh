#!/usr/bin/env bash

set -x
__DIR__=$(
  cd "$(dirname "$0")"
  pwd
)

cd ${__DIR__}

docker stop alpine-dev
docker stop debian-dev
docker stop ubuntu-dev
docker stop rhel-dev
docker stop archlinux-dev
docker stop php-alpine-dev
docker stop php-debian-dev
