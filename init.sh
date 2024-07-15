OS=$(uname -s)
if [ "${OS}" == 'Linux' ]; then
  OS_RELEASE=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '\n' | tr -d '\"')
  case "$OS_RELEASE" in
  'rocky' | 'almalinux' | 'alinux' | 'anolis' | 'fedora' | 'openEuler' | 'hce') # |  'amzn' | 'ol' | 'rhel' | 'centos'  # 未测试
    yum update -y
    yum install -y which
    ;;
  'ubuntu')
    if [ "$GITHUB_ACTIONS" = "true" ]; then
      sed -i.bak "s@security.ubuntu.com@azure.archive.ubuntu.com@g" /etc/apt/sources.list
      sed -i.bak "s@archive.ubuntu.com@azure.archive.ubuntu.com@g" /etc/apt/sources.list
    fi
    ;;
  'alpine')
    apk update
    apk add bash
    ;;
  'arch')
    pacman -Syyu --noconfirm
    pacman -Sy --noconfirm which
    ;;
  esac
fi
