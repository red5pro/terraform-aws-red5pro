#!/bin/bash
############################################################################################################
# 
############################################################################################################

RED5_HOME="/usr/local/red5pro"

log_i() {
    log
    printf "\033[0;32m [INFO]  --- %s \033[0m\n" "${@}"
}
log_d() {
    log
    printf "\033[0;33m [INFO]  --- %s \033[0m\n" "${@}"
}
log_w() {
    log
    printf "\033[0;35m [WARN] --- %s \033[0m\n" "${@}"
}
log_e() {
    log
    printf "\033[0;31m [ERROR]  --- %s \033[0m\n" "${@}"
}
log() {
    echo -n "[$(date '+%Y-%m-%d %H:%M:%S')]"
}
config_node() {
    log_i "Config NODE"

    local autoscale_pattern='<property name="active" value="false"/>'
    local autoscale_true='<property name="active" value="true"/>'

    sed -i -e "s|$autoscale_pattern|$autoscale_true|" "$RED5_HOME/conf/autoscale.xml"

    DIR="$RED5_HOME/webapps/secondscreen"
    if [ -d "$DIR" ]; then
        log_i "Delete unnecessary webapp ${DIR}..."
        rm -r $DIR
    fi

    DIR="$RED5_HOME/webapps/template"
    if [ -d "$DIR" ]; then
        log_i "Delete unnecessary webapp ${DIR}..."
        rm -r $DIR
    fi

    DIR="$RED5_HOME/webapps/vod"
    if [ -d "$DIR" ]; then
        log_i "Delete unnecessary webapp ${DIR}..."
        rm -r $DIR
    fi

    DIR="$RED5_HOME/webapps/streammanager"
    if [ -d "$DIR" ]; then
        log_i "Delete unnecessary webapp ${DIR}..."
        rm -r $DIR
    fi
}

config_node