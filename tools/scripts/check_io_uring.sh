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

mkdir -p ${__PROJECT__}/var/

cat >${__PROJECT__}/var/check_io_uring.c <<'EOF'
#include <errno.h>
#include <linux/io_uring.h>
#include <stddef.h>
#include <sys/syscall.h>
#include <unistd.h>

int main(int argc, char **argv) {
  if (syscall(__NR_io_uring_register, 0, IORING_UNREGISTER_BUFFERS, NULL, 0) && errno == ENOSYS) {
    // 不支持 io_uring
  } else {
    // 支持 io_uring
  }
}
EOF

{ gcc -x c -E -o /dev/null ${__PROJECT__}/var/check_io_uring.c; } || { echo '预处理 出现错误'; }

ldconfig -p | grep liburing
