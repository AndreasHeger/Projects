#!/usr/bin/env python
'''Monitor temperature.
'''

import logging
import urllib
from daemon import runner

import Utils
from Monitor import Monitor

FULL_URL = "http://www.wunderground.com/cgi-bin/findweather/getForecast?query=51.746%2C-1.296&sp=IOXFORDS54"
URL = "http://www.wunderground.com/personal-weather-station/dashboard?ID=IOXFORDS46#"

# 2 mins
HEART_BEAT = 120


class App(Monitor):

    label = "weather"

    def __init__(self, *args, **kwargs):
        Monitor.__init__(self, *args, **kwargs)

    def monitor(self):
        '''main loop.
        '''
        values = {}
        logger.debug('open URL')
            
        try:
            infile = urllib.urlopen(URL)
            logger.debug('opened URL')

            values = Utils.parseWeather(infile)
            logger.info("values collected: %s" % str(values))
            logger.info("status: weather=ok")

        except Exception, msg:
            logger.warn("error ignored: msg=%s" % str(msg))
            logger.info("status: weather=fail")

        return values

logger = logging.getLogger("DaemonLog")
logger.setLevel(logging.INFO)
formatter = logging.Formatter(
    "%(asctime)s - %(name)s - %(levelname)s - %(message)s")
handler = logging.FileHandler("/mnt/ramdisk/weather.log")
handler.setFormatter(formatter)
logger.addHandler(handler)
app = App(logger=logger, heart_beat=HEART_BEAT)

daemon_runner = runner.DaemonRunner(app)
# This ensures that the logger file handle does not get
# closed during daemonization
daemon_runner.daemon_context.files_preserve = [handler.stream]
daemon_runner.do_action()
