#! /bin/sh
### BEGIN INIT INFO
# Provides:          ro-apache 
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: start-up script for apache2 
# Description:       bypass apache2 startup through systemd, issue with r/o disk.
### END INIT INFO

# Author: Andreas Heger 
#
# This init script was written for Ubuntu 11.10 using start-stop-daemon.
# Note that you won't be able to stop the process with this script,
# use /usr/sbin/apache2ctl directly.
# 
# Enable with update-rc.d ro-apache defaults

# Source init-functions:
#source /lib/lsb/init-functions
. /lib/lsb/init-functions

NAME="ro-apache2"

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

DAEMON=/usr/sbin/apache2ctl

PIDFILE=/var/run/apache2.pid

SCRIPTNAME=/etc/init.d/$NAME

if [ ! -x "$DAEMON" ]; then {
    echo "Couldn't find $DAEMON or not executable"
    exit 99
}
fi

# Load the VERBOSE setting and other rcS variables
[ -f /etc/default/rcS ] && . /etc/default/rcS

# this line is reponsible for bypassing systemctl:
export APACHE_STARTED_BY_SYSTEMD=abc

#
# Function that starts the daemon/service
#
do_start()
{
    # Return
    #   0 if daemon has been started
    #   1 if daemon was already running
    #   2 if daemon could not be started
    
		# Test to see if the daemon is already running - return 1 if it is. 
    start-stop-daemon --start --pidfile $PIDFILE \
        --exec $DAEMON --test -- start > /dev/null || return 1
		
		# Start the daemon for real, return 2 if failed
    start-stop-daemon --start --pidfile $PIDFILE \
        --exec $DAEMON -- start > /dev/null || return 2
}

#
# Function that stops the daemon/service
#
do_stop() {
    # Return
    #   0 if daemon has been stopped
    #   1 if daemon was already stopped
    #   2 if daemon could not be stopped
    #   other if a failure occurred
    log_daemon_msg "Stopping $DESC" "$NAME"
    start-stop-daemon --stop --signal 2 --retry 5 --quiet --pidfile $PIDFILE
    RETVAL="$?"
    [ "$RETVAL" = 2 ] && return 2

		# Delete the exisitng PID file
    if [ -e "$PIDFILE" ]; then {
        rm $PIDFILE
    }
		fi
		
		return "$RETVAL"
}


# Display / Parse Init Options
case "$1" in
  start)
 	 [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
	  do_start
	  case "$?" in
	    0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
	    2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	  esac
  ;;
  stop)
 	 [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
	  do_stop
	  case "$?" in
	    0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
	    2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	  esac
  ;;
  restart)
  	log_daemon_msg "Restarting $DESC" "$NAME"
		do_stop
		  case "$?" in
		    0|1)
		    do_start
		    case "$?" in
		      0) log_end_msg 0 ;;
		      1) log_end_msg 1 ;; # Old process is still running
		      *) log_end_msg 1 ;; # Failed to start
		    esac
	   ;;
    *)
      # Failed to stop
    log_end_msg 1
    ;;
  esac
  ;;
  status)
      if [ -s $PIDFILE ]; then
          pid=`cat $PIDFILE`
          kill -0 $pid >/dev/null 2>&1
          if [ "$?" = "0" ]; then
              echo "$NAME is running: pid $pid."
              RETVAL=0
          else
              echo "Couldn't find pid $pid for $NAME."
              RETVAL=1
          fi
      else
          echo "$NAME is stopped (no pid file)."
          RETVAL=1
      fi
  ;;
  *)
  echo "Usage: $SCRIPTNAME {start|stop|restart|status}" >&2
  exit 3
  ;;
esac
:

