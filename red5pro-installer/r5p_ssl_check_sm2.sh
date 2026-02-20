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

HOME="/home/ubuntu/red5pro-installer"
SM_HOME="/usr/local/stream-manager"

if [ "$SM_SSL" == "letsencrypt" ]; then

    while true; do
        if [[ "$(dig +short "$SM_SSL_DOMAIN")" ]]; then
            log_i "DNS record for domain: $SM_SSL_DOMAIN was found."
            if [ -f "$HOME/autoscaling-with-ssl/docker-compose.yml" ]; then
                rm -rf "$SM_HOME/docker-compose.yml"
                cp -r "$HOME/autoscaling-with-ssl/docker-compose.yml" "$SM_HOME/"
                log_i "Restarting Stream Manager service to apply SSL configuration"
                systemctl restart sm.service
                log_i "Stream Manager service restarted"
                break
            else
                log_e "File $HOME/autoscaling-with-ssl/docker-compose.yml not found"
                ls -la "$HOME/autoscaling-with-ssl/"
                exit 1
            fi
        else
            log_i "DNS record for domain: $SM_SSL_DOMAIN was not found."
        fi
        sleep 60
    done
fi
