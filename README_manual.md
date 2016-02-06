#!/bin/bash

:<<COMMENT
http://linux-sunxi.org/UEnv.txt
http://www.tinyonetutorials.com/pdf/Banana%20PI%20%20user%20manual.pdf

# Howto compile
http://wiki.lemaker.org/BananaPro/Pi:Building_u-boot,_script.bin_and_linux-kernel
http://wiki.lemaker.org/BananaPro/Pi:Setting_up_the_bootable_SD_card

#serial pins...
http://linux-sunxi.org/images/thumb/2/2e/Lemaker_BananaPI_uart.jpg/240px-Lemaker_BananaPI_uart.jpg
http://linux-sunxi.org/LeMaker_Banana_Pi

COMMENT

# build kernel and uboot files
docker build -f Docekrfile.manual -t bpiuboot .
docker run -it -v $(pwd)/out:/lemaker-bsp/build/ bpiuboot


cd out/BananaPi_hwpack

# flash uboot bin
cd bootloader/
sudo dd if=u-boot-sunxi-with-spl.bin of=/dev/sdc bs=1024 seek=8
cd ..

# mount kernel
mount /dev/mmcblk0p1 /mnt/
sudo cp kernel/* /mnt/

# create (uEnv.txt) OR (boot.cmd and mkimage)

umount /mnt/


# unpack rootfs
mount /dev/mmcblk0p2 /mnt/

wget https://github.com/hypriot/os-rootfs/releases/download/v0.6.1/rootfs-armhf.tar.gz
sudo tar xvzf rootfs-armhf.tar.gz -C /mnt/

# add kernel modules ...
cd rootfs/
sudo cp -r * /mnt/

# create /etc/fstab file

umount /mnt/



