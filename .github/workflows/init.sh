OS_RELEASE=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '\n' | tr -d '\"')
case "$OS_RELEASE" in
'rocky' | 'almalinux' | 'alinux' | 'anolis' | 'fedora' | 'rhel' )
  yum update -y
  yum install -y which
  ;;
'ubuntu')
  sed -i.bak "s@security.ubuntu.com@azure.archive.ubuntu.com@g" /etc/apt/sources.list
  sed -i.bak "s@archive.ubuntu.com@azure.archive.ubuntu.com@g" /etc/apt/sources.list
  ;;
'alpine')
  apk update
  apk add bash
  ;;
esac
