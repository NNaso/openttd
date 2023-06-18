#!/bin/bash
set -e
source /tmp/buildconfig
source /etc/os-release
set -x

## Temporarily disable dpkg fsync to make building faster.
if [[ ! -e /etc/dpkg/dpkg.cfg.d/docker-apt-speedup ]]; then
	echo force-unsafe-io > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup
fi

## Update pkg repos
apt update -qq

## Install things we need
$minimal_apt_get_install dumb-init wget unzip xz-utils ca-certificates libc6 liblzo2-2 zlib1g liblzma5  > /dev/null 2>&1
env -i bash -c '. /etc/os-release; echo $VERSION_CODENAME'
OS_TARGET=${ID}-${VERSION_CODENAME}
if [[ $(curl https://cdn.openttd.org/openttd-releases/${OPENTTD_VERSION}/openttd-${OPENTTD_VERSION}-linux-${OS_TARGET}-amd64.deb) ]] 2>/dev/null;
	then
		echo "Non generic build exists."
		## Download and install openttd
		wget -q https://cdn.openttd.org/openttd-releases/${OPENTTD_VERSION}/openttd-${OPENTTD_VERSION}-linux-${OS_TARGET}-amd64.deb
		dpkg -i openttd-${OPENTTD_VERSION}-linux-${OS_TARGET}-amd64.deb
	else
		OS_TARGET=generic
		mkdir -p /usr/games/openttd
		cd /usr/games
		wget -q https://cdn.openttd.org/openttd-releases/${OPENTTD_VERSION}/openttd-${OPENTTD_VERSION}-linux-${OS_TARGET}-amd64.tar.xz
		tar -xf openttd-${OPENTTD_VERSION}-linux-generic-amd64.tar.xz
		mv openttd-${OPENTTD_VERSION}-linux-generic-amd64/* /usr/games/openttd
		rm -f openttd-${OPENTTD_VERSION}-linux-generic-amd64.tar.xz
		rm -r openttd-${OPENTTD_VERSION}-linux-generic-amd64
fi

## Download GFX and install
if [ -d /usr/games/openttd ]
	then
		cd /usr/games/openttd/baseset/
	else
		mkdir -p /usr/share/games/openttd/baseset/
		cd /usr/share/games/openttd/baseset/
fi
wget -q -O opengfx-${OPENGFX_VERSION}.zip https://cdn.openttd.org/opengfx-releases/${OPENGFX_VERSION}/opengfx-${OPENGFX_VERSION}-all.zip

unzip opengfx-${OPENGFX_VERSION}.zip
tar -xf opengfx-${OPENGFX_VERSION}.tar
rm -f opengfx-*.tar opengfx-*.zip

## Create user
adduser --disabled-password --uid 1000 --shell /bin/bash --gecos "" openttd

## Set entrypoint script to right user
chmod +x /openttd.sh
if [ -d /usr/games/openttd ]
then
    chmod +x /usr/games/openttd/openttd
fi