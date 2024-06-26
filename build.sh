#! /bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#update system
apt update

#install git
DEBIAN_FRONTEND=noninteractive apt install git lsb-release sudo tzdata -y

#create folder
mkdir build-zimbra

cd build-zimbra

#clone repository
git clone https://github.com/ianw1974/zimbra-build-scripts

#install deps
zimbra-build-scripts/zimbra-build-helper.sh --install-deps

mkdir installer-build
cd installer-build

#clone repository build tool
git clone --depth 1 --branch develop https://github.com/Zimbra/zm-build.git

cd zm-build
ENV_CACHE_CLEAR_FLAG=true 

#build...
./build.pl --ant-options -DskipTests=true --git-default-tag=10.0.8,10.0.7,10.0.6,10.0.5,10.0.4,10.0.3,10.0.2,10.0.1,10.0.0-GA --build-release-no=10.0.8 --build-type=FOSS --build-release=LIBERTY --build-release-candidate=GA --build-thirdparty-server=files.zimbra.com --no-interactive


tgz_file=$(find . -type f -name '*.tgz' -print -quit)

if [ -z "$tgz_file" ]; then
    echo "No se encontró ningún archivo .tgz en el directorio actual."
    exit 1
fi

cp "$tgz_file" /home/

docker run --rm --name "zimbrabuild_ubuntu20" -v $PWD/volume:/home/git/BUILDS -v $PWD/ssh:/root/.ssh -e BUILD_NO="0001" -e BUILD_RELEASE="DAFFODIL" -e BUILD_RELEASE_NO="10.0.6" -e BUILD_OS="UBUNTU20_64" -e BUILD_ARCH="amd64" -e BUILD_TYPE="FOSS" -e PKG_OS_TAG="u20" -e BUILD_RELEASE_CANDIDATE="GA" -e BUILD_THIRDPARTY_SERVER="files.zimbra.com" -e INTERACTIVE="0" docker.io/ovox/zimbrabuild-ubuntu20:latest