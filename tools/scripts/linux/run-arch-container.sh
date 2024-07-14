#!/bin/bash

set -exu
__DIR__=$(
  cd "$(dirname "$0")"
  pwd
)
__PROJECT__=$(
  cd ${__DIR__}/../../../
  pwd
)
cd ${__DIR__}

{
  docker stop archlinux-dev
  sleep 5
} || {
  echo $?
}
cd ${__DIR__}

IMAGE=archlinux:base

MIRROR=''
while [ $# -gt 0 ]; do
  case "$1" in
  --mirror)
    MIRROR="$2"
    case "$MIRROR" in
      china | openatom)
        echo '暂不可用'
        # IMAGE="hub.atomgit.com/library/archlinux:base"
        ;;
    esac
    ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

cd ${__DIR__}
docker run --rm --name archlinux-dev -d -v ${__PROJECT__}:/work -w /work -e TZ='Etc/UTC' $IMAGE tail -f /dev/null
