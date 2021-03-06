#!/bin/bash
#
# 2015-03-15
# github.com/mckaydavis
# STM32F0 Discovery Toolchain

# exit bash on error
set -e

# print command being executed to stderr
set -x

# Base directory for the toolchain
TOOLCHAIN_PREFIX=${TOOLCHAIN_PREFIX:-/usr/local}
BASE=${TOOLCHAIN_PREFIX}/stm32

# domain/path of apt mirror
APT_REPO=${APT_REPO:-mirror.ancl.hawaii.edu/linux}

# Quiet APT on non-interactive terminals
DEBIAN_FRONTEND=noninteractive

# Substitute default apt repos with the mirror location
sed -i \
  -e "s:http.debian.net:${APT_REPO}:g" \
  -e "s:archive.ubuntu.com:${APT_REPO}:g" \
  -e "s:security.ubuntu.com:${APT_REPO}:g" \
  /etc/apt/sources.list


# For Debian, get apt-add-repository for PPAs (disabled for now)
# apt-get update
# apt-get install -y software-properties-common python-software-properties

# PPA containing the gcc-arm-none-abi distributed by ARM Corp.
# https://launchpad.net/~terry.guo/+archive/ubuntu/gcc-arm-embedded
apt-get remove -y \
  binutils-arm-none-eabi \
  gcc-arm-none-eabi \
  || true # to allow non-zero exit

add-apt-repository ppa:terry.guo/gcc-arm-embedded

# PPA is for Ubuntu, so patch apt source for Debian to equivalent Ubuntu release
# (disabled for now)
# sed -i "s:wheezy:trusty:g" /etc/apt/sources.list.d/terry_guo-gcc-arm-embedded-wheezy.list

apt-get update

apt-get install -y \
  gcc-arm-none-eabi \
  unzip \
  git \
  libusb-1.0.0-dev \
  pkg-config \
  autotools-dev \
  autoconf

apt-get -y autoremove
apt-get -y clean
apt-get -y autoclean

# Create base toolchain dir
mkdir -p ${BASE}

# Download STM32F0 Discovery Firmware
cd ${BASE}
curl -Os http://www.st.com/st-web-ui/static/active/en/st_prod_software_internet/resource/technical/software/firmware/stm32f0discovery_fw.zip

# Unzip and overwrite (-o) to allow multiple provision runs
unzip -o stm32f0discovery_fw.zip


# github_get(github_path)
# clones a new or pulls an existing github repo
function github_get(){
  DIR=${1#*/}
  if [ ! -d "$DIR" ]
  then
    git clone git://github.com/${1}
    cd ${DIR}
  else
    # sync the latest code
    cd $DIR
    git pull
  fi
}


# stm32 discovery line linux programmer
cd ${BASE}
github_get texane/stlink
./autogen.sh
./configure --prefix=${STM_TOOLCHAIN_PREFIX}
make
make install

# copy udev device id rules from stlink
cp -f ${BASE}/stlink/49-stlinkv2.rules /etc/udev/rules.d/
udevadm control --reload-rules

# Simple blinking lights code
cd ${BASE}
github_get halherta/iotogglem0
make

# Fixup permissions for default vagrant user
chown -R vagrant:vagrant ${TOOLCHAIN_PREFIX}
ln -s ${BASE} /home/vagrant/stm32


