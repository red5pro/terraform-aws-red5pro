#!/bin/bash
######################################
# Install and configure RabbitMQ Server
######################################
# RMQ_USER="red5pro"
# RMQ_PASSWORD="password"
# RMQ_VHOST="red5pro"

set -euo pipefail

RMQ_VHOST="${RMQ_VHOST:-red5pro}"
RMQ_VHOST_DESCRIPTION="Red5 Pro cluster messaging"

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_SUSPEND=1

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

check_variables() {
    if [ -z "${RMQ_USER:-}" ]; then
        log_e "Variable RMQ_USER is empty."
        exit 1
    fi
    if [ -z "${RMQ_PASSWORD:-}" ]; then
        log_e "Variable RMQ_PASSWORD is empty."
        exit 1
    fi
}

wait_for_apt() {
    if command -v flock &>/dev/null; then
        while ! flock -n /var/lib/apt/lists/lock true; do
            log_i "apt is locked, wait 5 sec"
            sleep 5
        done
    fi
}

install_pkg() {
    for i in {1..5}; do
        local install_issue=0
        apt-get -y update --fix-missing || true

        for index in ${!packages[*]}; do
            log_i "Install package ${packages[$index]}"
            apt-get install -y ${packages[$index]} || true
        done

        for index in ${!packages[*]}; do
            local PKG_OK
            PKG_OK=$(dpkg-query -W --showformat='${Status}\n' ${packages[$index]} | grep "install ok installed" || true)
            if [ -z "$PKG_OK" ]; then
                log_i "${packages[$index]} package didn't install, didn't find MIRROR !!! "
                install_issue=$((install_issue + 1))
            else
                log_i "${packages[$index]} package installed"
            fi
        done

        if [ ${install_issue} -eq 0 ]; then
            break
        fi
        if [ $i -ge 5 ]; then
            log_e "Something wrong with packages installation!!! Exit."
            exit 1
        fi
        sleep 20
    done
}

add_rabbitmq_repository() {
    log_i "Add RabbitMQ and Erlang apt repositories"
    local codename
    codename=$(. /etc/os-release && echo "$VERSION_CODENAME")

    packages=(curl gnupg apt-transport-https ca-certificates)
    install_pkg

    curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" | gpg --dearmor --yes -o /usr/share/keyrings/com.rabbitmq.team.gpg
    curl -1sLf "https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key" | gpg --dearmor --yes -o /usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg
    curl -1sLf "https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key" | gpg --dearmor --yes -o /usr/share/keyrings/rabbitmq.9F4587F226208342.gpg

    cat >/etc/apt/sources.list.d/rabbitmq.list <<EOF
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu ${codename} main
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu ${codename} main
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu ${codename} main
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu ${codename} main
EOF
}

install_rabbitmq() {
    log_i "Install Erlang and RabbitMQ"
    packages=(erlang-base erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key erlang-runtime-tools erlang-snmp erlang-ssl erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl rabbitmq-server)
    install_pkg

    systemctl enable rabbitmq-server
    systemctl start rabbitmq-server
    rabbitmqctl await_startup
}

config_rabbitmq() {
    log_i "Configure RabbitMQ"
    rabbitmq-plugins enable rabbitmq_management

    if ! rabbitmqctl -q list_vhosts name | grep -qx "$RMQ_VHOST"; then
        rabbitmqctl add_vhost "$RMQ_VHOST" --description "$RMQ_VHOST_DESCRIPTION"
    fi

    if rabbitmqctl -q list_users | awk '{print $1}' | grep -qx "$RMQ_USER"; then
        rabbitmqctl change_password "$RMQ_USER" "$RMQ_PASSWORD"
    else
        rabbitmqctl add_user "$RMQ_USER" "$RMQ_PASSWORD"
    fi
    rabbitmqctl set_user_tags "$RMQ_USER" administrator

    rabbitmqctl set_permissions -p "$RMQ_VHOST" "$RMQ_USER" ".*" ".*" ".*"
    rabbitmqctl set_permissions -p / "$RMQ_USER" ".*" ".*" ".*"

    rabbitmqctl -q list_vhosts name
    rabbitmqctl -q list_users
}

check_variables
wait_for_apt
add_rabbitmq_repository
install_rabbitmq
config_rabbitmq
log_i "RabbitMQ installed and configured"
