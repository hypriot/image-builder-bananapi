FROM ubuntu:trusty

RUN apt-get update -qq && \
apt-get install -qq --force-yes --yes --no-install-recommends \
git \
make \
build-essential \
u-boot-tools \
kernel-package \
wget \
zip \
unzip \
tree \
ca-certificates \
fakeroot \
pkg-config \
ccache \
ruby \
ruby-dev \
pigz \
awscli
#shellcheck

RUN apt-get install -qq --yes --no-install-recommends \
cpp-arm-linux-gnueabihf \
g++-arm-linux-gnueabihf \
gcc-arm-linux-gnueabihf \
gcc-4.8-arm-linux-gnueabihf \
gcc-4.8-arm-linux-gnueabihf-base \
gcc-4.8-multilib-arm-linux-gnueabihf \
g++-4.8-arm-linux-gnueabihf \
g++-4.8-multilib-arm-linux-gnueabihf \
cpp-4.8-arm-linux-gnueabihf \
binutils-arm-linux-gnueabihf \
gcc-arm-none-eabi

RUN apt-get install -qq --yes --no-install-recommends \
libusb-1.0-0 \
libusb-1.0-0-dev \
libusb-dev \
libusb++-dev \
zlib1g-dev \
libncurses5-dev

RUN apt-get install -qq --yes --no-install-recommends \
binfmt-support \
qemu \
qemu-user-static

WORKDIR /workspace
CMD ["./builder/build.sh"]
