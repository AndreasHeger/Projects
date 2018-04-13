apt-get install apt-transport-https curl
curl https://bintray.com/user/downloadSubjectPublicKey?username=bintray | sudo apt-key add -

echo "deb https://dl.bintray.com/fg2it/deb stretch main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

apt-get update
apt-get install grafana

mv /var/lib/grafana /mnt/ramdisk/grafana
ln -s /mnt/ramdisk/grafana /var/lib/grafana

systemctl enable grafana-server.service
