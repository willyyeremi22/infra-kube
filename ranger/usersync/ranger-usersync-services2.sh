#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function getInstallProperty() {
    local propertyName=$1
    local propertyValue=""

    for file in "${INSTALL_ARGS}"
    do
        if [ -f "${file}" ]
        then
            propertyValue=`grep "^${propertyName}[ \t]*=" ${file} | awk -F= '{  sub("^[ \t]*", "", $2); sub("[ \t]*$", "", $2); print $2 }'`
            if [ "${propertyValue}" != "" ]
            then
                break
            fi
        fi
    done

    echo ${propertyValue}
}

if [[ -z $1 ]]; then
        echo "Invalid argument [$1];"
        echo "Usage: Only start | stop | restart | version, are supported."
        exit;
fi
action=$1
action=`echo $action | tr '[:lower:]' '[:upper:]'`
realScriptPath=`readlink -f $0`
realScriptDir=`dirname $realScriptPath`
cd $realScriptDir
cdir=`pwd`
ranger_usersync_max_heap_size=1g

for custom_env_script in `find ${cdir}/conf/ -name "ranger-usersync-env*"`; do
        if [ -f $custom_env_script ]; then
                . $custom_env_script
        fi
done
if [ -z "${USERSYNC_PID_DIR_PATH}" ]; then
        USERSYNC_PID_DIR_PATH=/var/run/ranger
fi
if [ -z "${USERSYNC_PID_NAME}" ]
then
        USERSYNC_PID_NAME=usersync.pid
fi
if [ ! -d "${USERSYNC_PID_DIR_PATH}" ]
then  
        mkdir -p  $USERSYNC_PID_DIR_PATH
        chmod 660 $USERSYNC_PID_DIR_PATH
fi

# User can set their own pid path using USERSYNC_PID_DIR_PATH and
# USERSYNC_PID_NAME variable before calling the script. The user can modify
# the value of the USERSYNC_PID_DIR_PATH in ranger-usersync-env-piddir.sh to
# change pid path and set the value of USERSYNC_PID_NAME to change the
# pid file.
pidf=${USERSYNC_PID_DIR_PATH}/${USERSYNC_PID_NAME}

if [ -z "${UNIX_USERSYNC_USER}" ]; then
        UNIX_USERSYNC_USER=ranger
fi

INSTALL_ARGS="${cdir}/install.properties"
RANGER_BASE_DIR=$(getInstallProperty 'ranger_base_dir')

JAVA_OPTS=" ${JAVA_OPTS} -XX:MetaspaceSize=100m -XX:MaxMetaspaceSize=200m -Xmx${ranger_usersync_max_heap_size} -Xms1g "

    # Export JAVA_HOME
if [ -f ${cdir}/conf/java_home.sh ]; then
    . ${cdir}/conf/java_home.sh
fi

if [ "$JAVA_HOME" != "" ]; then
    export PATH=$JAVA_HOME/bin:$PATH
fi

cp="${cdir}/dist/*:${cdir}/lib/*:${cdir}/conf:${RANGER_USERSYNC_HADOOP_CONF_DIR}/*"

cd ${cdir}

if [ -z "${logdir}" ]; then
    logdir=${cdir}/logs
fi

if [ -z "${USERSYNC_CONF_DIR}" ]; then
    USERSYNC_CONF_DIR=${cdir}/conf
fi

echo "Starting Apache Ranger Usersync Service (foreground)..."

exec java -Dproc_rangerusersync -Djdk.tls.ephemeralDHKeySize=2048 -Dlogback.configurationFile=file:${USERSYNC_CONF_DIR}/logback.xml ${JAVA_OPTS} -Duser=${USER} -Dhostname=${HOSTNAME} -Dlogdir="${logdir}" -cp "${cp}" org.apache.ranger.authentication.UnixAuthenticationService -enableUnixAuth
