#!/bin/bash
############################################################################################################
# Script Name: r5p_install_sm2_oci.sh
# Description: This script install Stream Manager 2.0 instance with Docker containers (docker-compose)
# AUTHOR: Oles Prykhodko
# COMPANY: Infrared5, Inc.
# Date: 2024-11-07
############################################################################################################

# Variables
# SM_STANDALONE=""
# SM_SSL=""
# SM_SSL_DOMAIN=""

SM_HOME="/usr/local/stream-manager"
CURRENT_DIRECTORY=$(pwd)
PACKAGES=(ca-certificates curl)

log_i() {
    log
    printf "\033[0;32m [INFO]  --- %s \033[0m\n" "${@}"
}
log_d() {
    log
    printf "\033[0;33m [DEBUG]  --- %s \033[0m\n" "${@}"
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

install_pkg() {
    for i in {1..20}; do

        local install_issuse=0
        apt-get -y update --fix-missing &>/dev/null

        for index in ${!PACKAGES[*]}; do
            log_i "Install utility ${PACKAGES[$index]}"
            apt-get install -y ${PACKAGES[$index]} &>/dev/null
        done

        for index in ${!PACKAGES[*]}; do
            PKG_OK=$(dpkg-query -W --showformat='${Status}\n' ${PACKAGES[$index]} | grep "install ok installed")
            if [ -z "$PKG_OK" ]; then
                log_i "${PACKAGES[$index]} utility didn't install. Will try again"
                install_issuse=$(($install_issuse + 1))
            else
                log_i "${PACKAGES[$index]} utility installed"
            fi
        done

        if [ $install_issuse -eq 0 ]; then
            break
        fi
        if [ $i -ge 20 ]; then
            log_e "Something wrong with packages installation!!! Exit."
            exit 1
        fi
        sleep 30
    done
}

install_docker() {
    log_i "Install Docker"

    # Add Docker's official GPG key:
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
        tee /etc/apt/sources.list.d/docker.list >/dev/null

    # Install Docker
    PACKAGES=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
    install_pkg

    # Add user to the docker group
    usermod -aG docker ubuntu
}

config_sm() {
    log_i "Config Stream Manager"

    mkdir -p "$SM_HOME"

    log_i "Copy sm.service file to /lib/systemd/system/sm.service"
    if [ -f "$CURRENT_DIRECTORY/sm.service" ]; then
        cp "$CURRENT_DIRECTORY/sm.service" /lib/systemd/system/sm.service
    else
        log_e "File $CURRENT_DIRECTORY/sm.service not found"
        ls -la "$CURRENT_DIRECTORY/"
        exit 1
    fi

    if [ "$SM_SSL" == "letsencrypt" ]; then
        log_i "Stream Manager 2.0 with Let's Encrypt SSL"

        mkdir -p "$SM_HOME/certs"

       # Copy docker-compose.yml
        if [ -f "$CURRENT_DIRECTORY/autoscaling-without-ssl/docker-compose.yml" ]; then
            cp -r "$CURRENT_DIRECTORY/autoscaling-without-ssl/docker-compose.yml" "$SM_HOME/"
        else
            log_e "File $CURRENT_DIRECTORY/autoscaling-without-ssl/docker-compose.yml not found"
            ls -la "$CURRENT_DIRECTORY/autoscaling-without-ssl/"
            exit 1
        fi

    elif [ "$SM_SSL" == "imported" ]; then
        log_i "Stream Manager 2.0 with imported SSL"

        mkdir -p "$SM_HOME/certs"

        # Copy docker-compose.yml
        if [ -f "$CURRENT_DIRECTORY/autoscaling-with-ssl/docker-compose.yml" ]; then
            cp -r "$CURRENT_DIRECTORY/autoscaling-with-ssl/docker-compose.yml" "$SM_HOME/"
        else
            log_e "File $CURRENT_DIRECTORY/autoscaling-with-ssl/docker-compose.yml not found"
            ls -la "$CURRENT_DIRECTORY/autoscaling-with-ssl/"
            exit 1
        fi
    else
        log_i "Stream Manager 2.0 without SSL"

        # Copy docker-compose.yml
        if [ -f "$CURRENT_DIRECTORY/autoscaling-without-ssl/docker-compose.yml" ]; then
            cp -r "$CURRENT_DIRECTORY/autoscaling-without-ssl/docker-compose.yml" "$SM_HOME/"
        else
            log_e "File $CURRENT_DIRECTORY/autoscaling-without-ssl/docker-compose.yml not found"
            ls -la "$CURRENT_DIRECTORY/autoscaling-without-ssl/"
            exit 1
        fi
    fi

    # log_i "Debug info"
    # cat "$SM_HOME/.env"
}

pull_docker_images() {
    log_i "Pull Docker images"
    cd "$SM_HOME" || exit 1
    if docker compose pull >/dev/null 2>&1; then
        log_i "Docker images pulled"
    else
        log_e "Docker images not pulled"
        exit 1
    fi
}

start_sm() {
    log_i "Start SM2.0 service"
    systemctl daemon-reload
    systemctl enable sm.service

    if [ "$SM_STANDALONE" == "true" ]; then
        log_i "Stream Manager 2.0 standalone mode - start service"
        systemctl start sm.service
        sleep 5

        # Check if the service is running
        if systemctl is-active --quiet sm.service; then
            log_i "Stream Manager 2.0 service is running"
        else
            log_e "Stream Manager 2.0 service is not running"
            exit 1
        fi

        if [ "$SM_SSL" == "letsencrypt" ]; then

            if [ -z "$SM_SSL_DOMAIN" ]; then
                log_e "Variable SM_SSL_DOMAIN is empty."
                exit 1
            fi

            if [ ! -f "$CURRENT_DIRECTORY/r5p_ssl_check_sm2.sh" ]; then
                log_e "File $CURRENT_DIRECTORY/r5p_ssl_check_sm2.sh not found"
                ls -la "$CURRENT_DIRECTORY/"
                exit 1
            fi

            # Modify DNS servers in systemd-resolved to use Google DNS servers because of long propagation in AWS DNS servers
            log_i "Modify DNS servers in systemd-resolved"
            echo "DNS=8.8.8.8 8.8.4.4" >>/etc/systemd/resolved.conf
            echo "FallbackDNS=2001:4860:4860::8888 2001:4860:4860::8844" >>/etc/systemd/resolved.conf
            systemctl restart systemd-resolved

            log_i "Start SSL check script"
            export SM_SSL_DOMAIN="$SM_SSL_DOMAIN"
            nohup sudo -E "$CURRENT_DIRECTORY/r5p_ssl_check_sm2.sh" >>"$CURRENT_DIRECTORY/r5p_ssl_check_sm2.log" &
        fi

    fi
}

if [ "$EUID" -ne 0 ]; then
    log_e "Please run as root"
    exit 1
fi

if command -v flock &>/dev/null; then
    log_i "Check if apt is locked"
    while ! flock -n /var/lib/apt/lists/lock true; do
        echo "apt is locked, wait 5 sec"
        sleep 5
    done
fi

install_pkg
install_docker
config_sm
pull_docker_images
start_sm