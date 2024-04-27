#! /bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export PATH=/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/home/jad/bin:/usr/sbin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin

#update && upgrade system
apt update && apt upgrade  -y

#install git
apt install git -y

#create folder
mkdir build-zimbra

cd build-zimbra

#clone repository
git clone https://github.com/ianw1974/zimbra-build-scripts

#install deps
zimbra-build-scripts/zimbra-build-helper.sh --install-deps

mkdir installer-build
cd installer-build
git clone --depth 1 --branch develop https://github.com/Zimbra/zm-build.git
cd zm-build
ENV_CACHE_CLEAR_FLAG=true 
./build.pl --ant-options -DskipTests=true --git-default-tag=10.0.6,10.0.5,10.0.4,10.0.3,10.0.2,10.0.1,10.0.0-GA,10.0.0 --build-release-no=10.0.6 --build-type=FOSS --build-release=Daffodil --build-release-candidate=GA --build-thirdparty-server=files.zimbra.com --no-interactive