#!/bin/bash
#
# startup script for TP-Link's EAP Controller.
#
### BEGIN INIT INFO
# Provides:          omada
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Omada Controller
# Description:       TP-Link's Omada Controller.
### END INIT INFO

NAME="omada"
DESC="Omada Controller"

OMADA_HOME=$(dirname $(dirname $(readlink -f $0)))
LOG_DIR="${OMADA_HOME}/logs"
WORK_DIR="${OMADA_HOME}/work"
DATA_DIR="${OMADA_HOME}/data"
PROPERTY_DIR="${OMADA_HOME}/properties"
AUTOBACKUP_DIR="${DATA_DIR}/autobackup"

JRE_HOME="$( readlink -f "$( which java )" | sed "s:bin/.*$::" )"
JAVA_TOOL="${JRE_HOME}/bin/java"
# reduce memory to prevent crash on 1GB systems and preseve the file from vendor.
# dont operate on /etc/init.d/tpeap as it needs to remain a symlink for the script
# to work: OMADA_HOME=$(dirname $(dirname $(readlink -f $0)))
# removed JVM tuning flags from upstream to let Java do its thing...
JAVA_OPTS="-server -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${LOG_DIR}/java_heapdump.hprof -Djava.awt.headless=true -XX:MaxRAMPercentage=40"
MAIN_CLASS="com.tplink.smb.omada.starter.OmadaLinuxMain"

OMADA_USER=${OMADA_USER:-omada}
OMADA_GROUP=$(id -gn ${OMADA_USER})

PID_FILE="/var/run/${NAME}.pid"

help() {
    echo "usage: $0 help"
    echo "       $0 (start|stop|status|version)"
    cat <<EOF

help       - this screen
start      - start the service(s)
stop       - stop  the service(s)
status     - show the status of the service(s)
version    - show the version of the service(s)

EOF
}

# root permission check
check_root_perms() {
    [ $(id -ru) != 0 ] && { echo "You must be root to execute this script. Exit." 1>&2; exit 1; }
}

# check if ${OMADA_USER} has the permission to ${DATA_DIR} ${LOG_DIR} ${WORK_DIR}
check_omada_user() {
    OMADA_UID=$(id -u ${OMADA_USER})
    [ 0 != $? ] && {
        echo "Failed to start ${DESC}. Please create user ${OMADA_USER} user"
        exit 1
    }

    if [ ${OMADA_UID} -ne $(stat ${DATA_DIR} -Lc %u) ]; then
        echo "Failed to start ${DESC}. Please chown -R ${OMADA_USER} ${DATA_DIR} ${LOG_DIR} ${WORK_DIR}"
        exit 1
    fi

    [ -e "${LOG_DIR}" ] && [ ${OMADA_UID} -ne $(stat ${LOG_DIR} -Lc %u) ] && {
        echo "Failed to start ${DESC}. Please chown -R ${OMADA_USER} ${LOG_DIR}"
        exit 1
    }

    [ -e "${WORK_DIR}" ] && [ ${OMADA_UID} -ne $(stat ${WORK_DIR} -Lc %u) ] && {
        echo "Failed to start ${DESC}. Please chown -R ${OMADA_USER} ${WORK_DIR}"
        exit 1
    }
}

check_version() {
    echo "Omada Controller v5.13.22 for Linux (X64)"
}

# root permission check
check_root_perms

# JSVC - for running java apps as services
JSVC=$(command -v jsvc)
if [ -z ${JSVC} ] || [ ! -x ${JSVC} ]; then
    echo "${DESC}: jsvc not found, please install jsvc!"
    exit 1
fi

# curl
CURL=$(command -v curl)
if [ -z ${CURL} ] || [ ! -x ${CURL} ]; then
    echo "${DESC}: curl not found, please install curl!"
    exit 1
fi

# return: 1,running; 0, not running;
is_running() {
#    ps -U root -u root u | grep eap | grep -v grep >/dev/null
    [ -z "$(pgrep -f ${MAIN_CLASS})" ] && {
        return 0
    }

    return 1
}

[ ! -f ${PROPERTY_DIR}/omada.properties ] || HTTP_PORT=$(grep "^[^#;]" ${PROPERTY_DIR}/omada.properties | sed -n 's/manage.http.port=\([0-9]\+\)/\1/p' | sed -r 's/\r//')
HTTP_PORT=${HTTP_PORT:-8088}

#---------------------------------------------------

# return: 1,running; 0, not running;
is_in_service() {
    http_code=$(curl -I -m 10 -o /dev/null -s -w %{http_code} http://localhost:${HTTP_PORT}/actuator/linux/check)
    if [ "${http_code}" == "200" ]; then
         return 1
    elif [ "${http_code}" == "503" ]; then
            return 2
    elif [ "${http_code}" == "000" ]; then
            return 3
    else
         return 0
    fi
}

 # check whether jsvc requires -cwd option
${JSVC} -java-home ${JRE_HOME} -cwd / -help >/dev/null 2>&1
if [ $? -eq 0 ] ; then
    JSVC_OPTS="${JSVC_OPTS} -cwd ${OMADA_HOME}/lib"
fi

# modify to allow outdate reflection codes. jsvc doesnt support JDK_JAVA_OPTIONS (or at least v1.0.x doesnt)
# https://stackoverflow.com/a/77263854/3441106
JSVC_OPTS="${JSVC_OPTS} \
 --add-opens=java.base/java.lang=ALL-UNNAMED \
 --add-opens=java.base/java.io=ALL-UNNAMED \
 --add-opens=java.base/java.util=ALL-UNNAMED \
 --add-opens=java.base/java.util.concurrent=ALL-UNNAMED \
 --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED \
 --add-opens=java.base/java.math=ALL-UNNAMED \
 --add-opens=java.base/java.net=ALL-UNNAMED \
 --add-opens=java.base/java.text=ALL-UNNAMED \
 --add-opens=java.sql/java.sql=ALL-UNNAMED \
 --add-opens=java.base/java.lang.reflect=ALL-UNNAMED \
 -pidfile ${PID_FILE} \
 -home ${JRE_HOME} \
 -cp /usr/share/java/commons-daemon.jar:${OMADA_HOME}/lib/*:${OMADA_HOME}/properties \
 -outfile ${LOG_DIR}/startup.log \
 -errfile ${LOG_DIR}/startup.log \
 -user ${OMADA_USER} \
 -procname ${NAME} \
 -showversion \
 ${JAVA_OPTS}"

start() {
    is_running
    if  [ 1 == $? ]; then
        echo "${DESC} is already running. You can visit http://localhost:${HTTP_PORT} on this host to manage the wireless network."
        exit
    fi

    # check if ${OMADA_USER} has the permission to ${DATA_DIR} ${LOG_DIR} ${WORK_DIR}
    [ "root" != ${OMADA_USER} ] && {
        echo "check ${OMADA_USER}"
        check_omada_user
    }

    echo -n "Starting ${DESC}. Please wait."

    [ -e "${LOG_DIR}" ] || {
        mkdir -m 755 ${LOG_DIR} 2>/dev/null && chown -R ${OMADA_USER}:${OMADA_GROUP} ${LOG_DIR}
    }

    rm -f "${LOG_DIR}/startup.log"
    touch "${LOG_DIR}/startup.log" 2>/dev/null && chown ${OMADA_USER}:${OMADA_GROUP} "${LOG_DIR}/startup.log"


    [ -e "$WORK_DIR" ] || {
        mkdir -m 755 ${WORK_DIR} 2>/dev/null && chown -R ${OMADA_USER}:${OMADA_GROUP} ${WORK_DIR}
    }

    [ -e "$AUTOBACKUP_DIR" ] || {
        mkdir -m 755 ${AUTOBACKUP_DIR} 2>/dev/null && chown -R ${OMADA_USER}:${OMADA_GROUP} ${AUTOBACKUP_DIR}
    }

    ${JSVC} ${JSVC_OPTS} ${MAIN_CLASS} start

    count=0
    norp_count=0
    while true
    do
        is_in_service
        if  [ 1 == $? ] || [ 2 == $? ]; then
            break
        else
            sleep 1
            echo -n "."
            if  [ 3 == $? ]; then
                norp_count=`expr $norp_count + 1`
            fi
            count=`expr $count + 1`
            if [ $count -gt 2400 ] || [ $norp_count -gt 300 ]; then
                break
            fi
        fi
    done

    echo "."

    is_in_service
    if  [ 1 == $? ] || [ 2 == $? ]; then
        echo "Started successfully."
        echo You can visit http://localhost:${HTTP_PORT} on this host to manage the wireless network.
    else
        echo "Start failed."
    fi
}

stop() {
    is_running
    if  [ 0 == $? ]; then
        echo "${DESC} not running."
        exit
    fi

    echo -n "Stopping ${DESC} "
    ${JSVC} ${JSVC_OPTS} -stop ${MAIN_CLASS} stop

    count=0

    while true
    do
        is_running
        if  [ 0 == $? ]; then
            break
        else
            sleep 1
            count=`expr $count + 1`
            echo -n "."
            if [ $count -gt 30 ]; then
                break
            fi
        fi
    done

    echo ""

    is_running
    if  [ 0 == $? ]; then
        echo "Stop successfully."
    else
        echo "Stop failed. going to kill it."
        pkill -f ${MAIN_CLASS}
    fi
}

status() {
    is_running
    if  [ 0 == $? ]; then
        echo "${DESC} is not running."
    else
        echo "${DESC} is running. You can visit http://localhost:${HTTP_PORT} on this host to manage the wireless network."
    fi
}

# parameter check
if [ $# != 1 ]
then
    help
    exit
elif [[ $1 != "start" && $1 != "stop" && $1 != "status" && $1 != "version" ]]
then
    help
    exit
fi

if [ $1 == "start" ]; then
    start
elif [ $1 == "stop" ]; then
    stop
elif [ $1 == "status" ]; then
    status
elif [ $1 == "version" ]; then
    check_version
fi
