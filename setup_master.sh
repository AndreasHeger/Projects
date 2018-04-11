#!/bin/bash

echo "setting up: master-pi"
echo "master-pi" > /etc/hostname

# make sure rpcbind is started at boot
update-rc.d rpcbind enable

cat <<EOC | crontab
SHELL=/bin/bash
# daily backup from ramdisk to SD card
@daily  /etc/init.d/ramdisk sync >> /dev/null 2>&1
EOC

