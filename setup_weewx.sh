#wget -qO - http://weewx.com/keys.html | sudo apt-key add -
#wget -qO - http://weewx.com/apt/weewx.list | sudo tee /etc/apt/sources.list.d/weewx.list
#apt-get update
#apt-get install weewx

#echo "installing graphite extensions"

#wget https://github.com/ampledata/weewx_graphite/archive/master.tar.gz
#wee_extension --install master.tar.gz

service weewx stop
mv /var/lib/weewx/weewx.sdb /var/lib/weewx/weewx.sdb-old
wget -O weewx-kl.zip https://github.com/matthewwall/weewx-klimalogg/archive/master.zip
wee_extension --install weewx-kl.zip
wee_config --reconfigure --driver=user.kl --no-prompt

sed -i "s:CARBON_HOST:localhost:" /etc/weewx/weewx.conf
sed -i "s:CARBON_PORT:2003:" /etc/weewx/weewx.conf
mkdir /mnt/ramdisk/weewx
sed -i "s:SQLITE_ROOT = /var/lib/weewx:SQLITE_ROOT = /mnt/ramdisk/weewx:" /etc/weewx/weewx.conf
# remove [[StandardReport]]
# remove [[Simulater]

echo "make sure that USB dongle is plugged in"
service weewex start
