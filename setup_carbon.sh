# https://markinbristol.wordpress.com/2015/09/20/setting-up-graphite-api-grafana-on-a-raspberry-pi/

#apt-get install graphite-carbon

# Change to true, to enable carbon-cache on boot
sed -i "s/CARBON_CACHE_ENABLED=false/CARBON_CACHE_ENABLED=true/" /etc/default/graphite-carbon

mkdir -p /mnt/ramdisk/graphite/whisper
mkdir -p /mnt/ramdisk/graphite/log
chown -R _graphite:_graphite /mnt/ramdisk/graphite

# values below are ignored, those ith the systemd file taking precedence
sed -i "s:STORAGE_DIR    = /var/lib/graphite/:STORAGE_DIR = /mnt/ramdisk/graphite:" /etc/carbon/carbon.conf
sed -i "s:LOCAL_DATA_DIR = /var/lib/graphite/whisper/:LOCAL_DATA_DIR = /mnt/ramdisk/graphite/whisper:" /etc/carbon/carbon.conf
sed -i "s:LOG_DIR        = /var/log/carbon/:LOG_DIR = /mnt/ramdisk/graphite/log:" /etc/carbon/carbon.conf
sed -i "s:PID_DIR        = /var/run/:PID_DIR = /mnt/ramdisk/graphite:" /etc/carbon/carbon.conf
sed -i "s:ENABLE_LOGROTATION = False:ENABBLE_LOGROTATION = True:" /etc/carbon/carbon.conf

# ignored by systemd
sed -i "s:PIDFILE=/var/run/\$NAME.pid:PIDFILE=/mnt/ramdisk/graphite.pid:" /etc/init.d/carbon-cache
sed -i "s:--logdir=/var/log/carbon/:--logdir=/mnt/ramdisk/graphite/log:" /etc/init.d/carbon-cache

sed -i "s:--logdir=/var/log/carbon/:--logdir=/mnt/ramdisk/graphite/log:" /lib/systemd/system/carbon*

echo "installing graphite"
apt-get install python python-pip build-essential python-dev libcairo2-dev libffi-dev
pip install graphite-api

mkdir -p /mnt/ramdisk/graphite_index
chown www-data:www-data /mnt/ramdisk/graphite_index

# make sure that directory for apache2 logs exists
mkdir /var/log/apache2

echo "install graphite-api.yml"

cat <<EOT1 > /etc/graphite-api.yaml
search_index: /mnt/ramdisk/graphite_index/index
finders:
  - graphite_api.finders.whisper.WhisperFinder
functions:
  - graphite_api.functions.SeriesFunctions
  - graphite_api.functions.PieFunctions
whisper:
  directories:
    - /mnt/ramdisk/graphite/whisper
carbon:
  hosts:
    - 127.0.0.1:7002
  timeout: 1
  retry_delay: 15
  carbon_prefix: carbon
  replication_factor: 1
EOT1


echo "enabling graphite in apache"
apt-get install libapache2-mod-wsgi

echo "creating /var/www/wgsi-scripts/graphite-api.wsgi"
mkdir -p /var/www/wsgi-scripts
cat <<EOT2 > /var/www/wsgi-scripts/graphite-api.wsgi
# /var/www/wsgi-scripts/graphite-api.wsgi

from graphite_api.app import app as application
EOT2

echo "creating graphite.conf"
cat <<EOT3 > /etc/apache2/sites-available/graphite.conf

# /etc/apache2/sites-available/graphite.conf
LoadModule wsgi_module modules/mod_wsgi.so
WSGISocketPrefix /var/run/wsgi
Listen 8013
<VirtualHost *:8013>

 WSGIDaemonProcess graphite-api processes=5 threads=5 display-name='%{GROUP}' inactivity-timeout=120
 WSGIProcessGroup graphite-api
 WSGIApplicationGroup %{GLOBAL}
 WSGIImportScript /var/www/wsgi-scripts/graphite-api.wsgi process-group=graphite-api application-group=%{GLOBAL}

 WSGIScriptAlias / /var/www/wsgi-scripts/graphite-api.wsgi

 <Directory /var/www/wsgi-scripts/>
 Order deny,allow
 Allow from all
 </Directory>
 </VirtualHost>
EOT3

ln -s /etc/apache2/sites-available/graphite.conf /etc/apache2/sites-enabled/graphite.conf

