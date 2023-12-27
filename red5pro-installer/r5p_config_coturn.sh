#!/bin/bash
############################################################################################################
# Red5 Pro Coturn configuration for single Red5 Pro server and Red5 Pro Stream Manager                     #
############################################################################################################

# COTURN_ENABLE="true"
# COTURN_ADDRESS="stun:1.2.3.4:3478"

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

config_red5pro_coturn(){

    if [[ "$COTURN_ENABLE" == "true" ]]; then
        log_i "Red5Pro Coturn configuration - enable"
    
        if [ -z "$COTURN_ADDRESS" ]; then
            log_e "Parameter COTURN_ADDRESS is empty. EXIT."
            exit 1
        fi

        log_i "Config Coturn address: $RED5_HOME/conf/network.properties"
        stun_address='stun.address=.*'
        stun_address_new="stun.address=${NODE_CLOUDSTORAGE_AWS_BUCKET_ACL_POLICY}"

        sed -i -e "s|$stun_address|$stun_address_new|" "$RED5_HOME/conf/network.properties"

        log_i "Config Coturn address: $RED5_HOME/webapps/webrtcexamples/script/testbed-config.js"
        stun_google_address='stun:stun2.l.google.com:19302'
        stun_google_address_new="${COTURN_ADDRESS}"

        stun_mozilla_address='stun:stun.services.mozilla.com:3478'
        stun_mozilla_address_new="${COTURN_ADDRESS}"

        sed -i -e "s|$stun_google_address|$stun_google_address_new|" -e "s|$stun_mozilla_address|$stun_mozilla_address_new|" "$RED5_HOME/webapps/webrtcexamples/script/testbed-config.js"
    else
        log_d "Red5Pro Coturn configuration - disable"
    fi
}

config_red5pro_coturn