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

install_python3() {
  case "$OS" in
  Darwin | darwin)
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_INSTALL_FROM_API=1
    brew install python3
    ;;
  Linux)
    OS_RELEASE=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '\n' | tr -d '\"')
    case "$OS_RELEASE" in
    'rocky' | 'almalinux' | 'alinux' | 'anolis' | 'fedora' | 'openEuler' | 'hce') # |  'amzn' | 'ol' | 'rhel' | 'centos'  # 未测试
      yum install -y update
      yum install -y python3
      ;;
    'debian' | 'ubuntu' | 'kali')
      export DEBIAN_FRONTEND=noninteractive
      export TZ="Etc/UTC"
      ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
      apt update -y
      apt install -y python3 python3-pip

      ;;
    'alpine')
      apk update
      apk add python3 py3-pip
      ;;
    'arch')
      pacman -Sy --noconfirm python3 python3-pip

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

while [ $# -gt 0 ]; do
  case "$1" in
  --debug)
    set -x
    ;;
  --install-python3)
    if [ "$2" == "1" ]; then
      install_python3
    fi
    ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done
