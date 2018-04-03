#!/bin/sh

ps auxw | grep monitor_solar | grep -v grep > /dev/null

if [ $? != 0 ]
then
        /etc/init.d/monitor_solar start > /dev/null
fi
