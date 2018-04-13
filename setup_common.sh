# Commands to make a raspbian image RO.
# 
# See: http://openenergymonitor.org/emon/node/5331

apt-get -y update
apt-get -y upgrade

apt-get -y remove --purge wolfram-engine gmetad

# # Remove X-Server and related stuff:
apt-get -y remove --purge xserver-common lightdm
insserv -r x11-common

# # auto-remove some X11 related libs
apt-get -y autoremove --purge

# use busybox to log to memory
apt-get -y install busybox-syslogd
dpkg --purge rsyslog

# # install packages required for monitoring
apt-get -y install python-daemon apache2 python-serial

# turn off 
if [ ! -e /etc/default/rcS.orig ]; then
    cp /etc/default/rcS /etc/default/rcS.orig
    sh -c "echo 'RAMTMP=yes' >> /etc/default/rcS"
fi

mkdir /mnt/ramdisk
mkdir /mnt/diskstation

# create fstab
if [ ! -e /etc/fstab.orig ] ; then
    mv /etc/fstab /etc/fstab.orig
    sh -c "echo 'tmpfs           /tmp            tmpfs   nodev,nosuid,size=30M,mode=1777       0    0' >> /etc/fstab"
    sh -c "echo 'tmpfs           /var/log        tmpfs   nodev,nosuid,size=30M,mode=1777       0    0' >> /etc/fstab"
    sh -c "echo 'proc            /proc           proc    defaults                              0    0' >> /etc/fstab"
    sh -c "echo '/dev/mmcblk0p1  /boot           vfat    defaults                              0    2' >> /etc/fstab"
    sh -c "echo '/dev/mmcblk0p2  /               ext4    defaults,ro,noatime,errors=remount-ro 0    1' >> /etc/fstab"
    # add ramdisk for monitoring
    sh -c "echo 'tmpfs           /mnt/ramdisk    tmpfs   defaults,size=200M                    0    0' >> /etc/fstab"
    # add mount point for diskstation
    sh -c "echo '192.168.0.2:/volume1/data       /mnt/diskstation        nfs     user,noauto' >> /etc/fstab"
    sh -c "echo ' ' >> /etc/fstab"
fi

if [ ! -e /etc/mtab.orig ]; then
mv /etc/mtab /etc/mtab.orig
ln -fs /proc/self/mounts /etc/mtab
fi

cat <<EOT1 > /usr/bin/rpi-rw
#!/bin/sh
mount -o remount,rw /dev/mmcblk0p2  /
echo "Filesystem is unlocked - Write access"
echo "type ' rpi-ro ' to lock"
EOT1

cat <<EOT2 > /usr/bin/rpi-ro
#!/bin/sh
sudo mount -o remount,ro /dev/mmcblk0p2  /
echo "Filesystem is locked - Read Only access"
echo "type ' rpi-rw ' to unlock"
EOT2

chmod +x  /usr/bin/rpi-rw
chmod +x  /usr/bin/rpi-ro

mkdir /usr/share/solar
mkdir /usr/lib/cgi-bin

#######################################################
# echo "change /etc/init.d/apache2 to create log dir"
if [ ! -e //usr/sbin/apache2ctl.orig ] ; then
  cp /usr/sbin/apache2ctl /usr/sbin/apache2ctl.orig
  sed "s:ARGV="$@":ARGV="$@"\nmkdir /var/log/apache2 || true\n:" < /usr/sbin/apache2ctl.orig > /usr/sbin/apache2ctl 
fi

#######################################################
echo "installing systemd scripts for monitoring"
cp *.service /etc/systemd/system

#######################################################
echo "setting up web services"
cp *web.py Utils.py /usr/lib/cgi-bin/
cp Monitor.py Utils.py /usr/share/solar/
chown -R www-data:www-data /usr/lib/cgi-bin/*.py /mnt/ramdisk
cp images/*.png /mnt/ramdisk
ln -fs /mnt/ramdisk /var/www/images

##########################################################
#
echo "Setting up ramdisk backup"
mkdir /var/ramdisk-backup
cp ramdisk_backup.sh /etc/init.d/ramdisk
chmod 755 /etc/init.d/ramdisk
chown root:root /etc/init.d/ramdisk

update-rc.d ramdisk defaults 00 99
 
echo "# setting up daily ramdisk backup"
echo "@daily  /etc/init.d/ramdisk sync >> /dev/null 2>&1" | crontab

# If apache does not start up, 
# make sure /var/log/apache2 exists

# redirect several dirs to /tmp
rm -rf /var/lib/dhcp/ /var/lib/dhcpcd5 /var/run /var/spool /var/lock /etc/resolv.conf /var/log
ln -s /tmp /var/lib/dhcp
ln -s /tmp /var/lib/dhcpcd5
ln -s /tmp /var/run
ln -s /tmp /var/spool
ln -s /tmp /var/lock
ln -s /tmp /var/log
touch /tmp/dhcpcd.resolv.conf; ln -s /tmp/dhcpcd.resolv.conf /etc/resolv.conf
