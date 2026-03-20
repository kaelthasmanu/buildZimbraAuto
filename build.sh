#! /bin/bash

set -euo pipefail
IFS=$'\n\t'

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

usage() {
    cat <<EOF
Usage: $0 [--skip-build]

Options:
  --skip-build   solo instala dependencias y actualiza config.build, no ejecuta --build-zimbra
  --help         muestra esta ayuda
EOF
}

SKIP_BUILD=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-build) SKIP_BUILD=true; shift ;;
        --help) usage; exit 0 ;;
        *) echo "Parámetro desconocido: $1"; usage; exit 1 ;;
    esac
done

# update system
apt update

# install git + herramientas base
DEBIAN_FRONTEND=noninteractive apt install -y git lsb-release sudo tzdata curl openssh-client

# create/enter workspace
mkdir -p build-zimbra
cd build-zimbra

# validate zimbra.ver exists
if [ ! -f ../zimbra.ver ]; then
    echo "ERROR: no se encontró ../zimbra.ver"
    exit 1
fi

# parse variables from zimbra.ver
ZIMBRA_VER=$(grep -E '^ZIMBRA_VER=' ../zimbra.ver | cut -d'=' -f2 | tr -d '"')
BUILD_RELEASE=$(grep -E '^BUILD_RELEASE=' ../zimbra.ver | cut -d'=' -f2 | tr -d '"' || true)
BUILD_NO=$(grep -E '^BUILD_NO=' ../zimbra.ver | cut -d'=' -f2 | tr -d '"' || true)

if [ -z "$ZIMBRA_VER" ]; then
    echo "ERROR: ZIMBRA_VER no está definido en ../zimbra.ver"
    exit 1
fi

BUILD_RELEASE=${BUILD_RELEASE:-DAFFODIL}
BUILD_NO=${BUILD_NO:-0001}

# clone repository
if [ ! -d zimbra-build-scripts ]; then
    git clone https://github.com/ianw1974/zimbra-build-scripts
else
    echo "zimbra-build-scripts ya existe, actualizando..."
    cd zimbra-build-scripts
    git fetch --all --prune
    git reset --hard origin/main
    cd ..
fi

# prepare config.build
if [ ! -f ../config.build ]; then
    echo "ERROR: no se encontró ../config.build"
    exit 1
fi

cp ../config.build zimbra-build-scripts/config.build

# update vars in config.build
sed -i -E "s/^(BUILD_NO[[:space:]]*=).*/\1 $BUILD_NO/" zimbra-build-scripts/config.build
sed -i -E "s/^(BUILD_RELEASE[[:space:]]*=).*/\1 $BUILD_RELEASE/" zimbra-build-scripts/config.build
sed -i -E "s/^(BUILD_RELEASE_NO[[:space:]]*=).*/\1 $ZIMBRA_VER/" zimbra-build-scripts/config.build

# preserve defaults for other fields if no archivo principal
sed -i -E "s/^(BUILD_RELEASE_CANDIDATE[[:space:]]*=).*/\1 GA/" zimbra-build-scripts/config.build || true
sed -i -E "s/^(BUILD_TYPE[[:space:]]*=).*/\1 FOSS/" zimbra-build-scripts/config.build || true

cat <<EOF
Configuración aplicado:
  BUILD_NO=$BUILD_NO
  BUILD_RELEASE=$BUILD_RELEASE
  BUILD_RELEASE_NO=$ZIMBRA_VER
EOF

# check SSH key for GitHub
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "WARN: no existe ~/.ssh/id_rsa. Genera una clave SSH y añade la pública a GitHub antes de continuar."
else
    if ! ssh -o BatchMode=yes -T git@github.com 2>/dev/null; then
        echo "WARN: conexión SSH a github.com fallida. Asegura que tu clave esté registrada en GitHub y ssh-agent activado."
    fi
fi

# install deps and build
zimbra-build-scripts/zimbra-build-helper.sh --install-deps
if [ "$SKIP_BUILD" = false ]; then
    zimbra-build-scripts/zimbra-build-helper.sh --build-zimbra
else
    echo "skip-build habilitado: no se ejecuta --build-zimbra"
fi
