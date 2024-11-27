#!/bin/bash

# SM_SSL_DOMAIN

log_i() {
    log
    printf "\033[0;32m [INFO]  --- %s \033[0m\n" "${@}"
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

SM_HOME="/usr/local/stream-manager"

if [ -z "$SM_SSL_DOMAIN" ]; then
    log_e "Variable SM_SSL_DOMAIN is empty."
    exit 1
fi

while true; do
    if [[ "$(dig +short "$SM_SSL_DOMAIN")" ]]; then
        log_i "DNS record for domain: $SM_SSL_DOMAIN was found."
        log_i "Restart SM2.0 Traefik service..."
        cd "$SM_HOME" || exit 1
        docker compose restart reverse-proxy
        break
    else
        log_i "DNS record for domain: $SM_SSL_DOMAIN was not found."
    fi
    sleep 60
done