#!/bin/bash
######################################
# Install RabbitMQ Server with Docker Compose (single node or cluster node)
######################################
# RMQ_IMAGE="rabbitmq:4.3.6-management"
# RMQ_USER="red5pro"
# RMQ_PASSWORD="password"
# RMQ_VHOST="red5pro"
# RMQ_ERLANG_COOKIE="COOKIE"
# RMQ_NODE_INDEX="1"
# RMQ_NODE_IPS="10.5.0.10,10.5.1.10,10.5.2.10"

set -euo pipefail

RMQ_VHOST="${RMQ_VHOST:-red5pro}"
RMQ_VHOST_DESCRIPTION="Red5 Pro cluster messaging"
RMQ_HOME="/usr/local/rabbitmq"
RMQ_CLUSTER_TIMEOUT=600

CURRENT_DIRECTORY=$(pwd)

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
    local var
    for var in RMQ_IMAGE RMQ_USER RMQ_PASSWORD RMQ_ERLANG_COOKIE RMQ_NODE_INDEX RMQ_NODE_IPS; do
        if [ -z "${!var:-}" ]; then
            log_e "Variable $var is empty."
            exit 1
        fi
    done
    IFS=',' read -r -a NODE_IPS <<<"$RMQ_NODE_IPS"
    NODE_COUNT=${#NODE_IPS[@]}
    NODE_IP=${NODE_IPS[$((RMQ_NODE_INDEX - 1))]}
    log_i "RabbitMQ node $RMQ_NODE_INDEX of $NODE_COUNT, node name rabbit@$NODE_IP"
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

install_docker() {
    log_i "Install Docker"
    packages=(curl ca-certificates python3)
    install_pkg

    install -m 0755 -d /etc/apt/keyrings
    curl -4fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" >/etc/apt/sources.list.d/docker.list

    packages=(docker-ce docker-ce-cli containerd.io docker-compose-plugin)
    install_pkg
    usermod -aG docker ubuntu
}

config_rabbitmq() {
    log_i "Configure RabbitMQ in $RMQ_HOME"
    mkdir -p "$RMQ_HOME/data"

    printf '%s' "$RMQ_ERLANG_COOKIE" >"$RMQ_HOME/data/.erlang.cookie"
    chmod 400 "$RMQ_HOME/data/.erlang.cookie"
    chown -R 999:999 "$RMQ_HOME/data"

    {
        echo "listeners.tcp.default = 5672"
        echo "management.tcp.port = 15672"
        echo "disk_free_limit.relative = 1.0"
        if [ "$NODE_COUNT" -gt 1 ]; then
            echo "cluster_formation.peer_discovery_backend = classic_config"
            local i
            for i in "${!NODE_IPS[@]}"; do
                echo "cluster_formation.classic_config.nodes.$((i + 1)) = rabbit@${NODE_IPS[$i]}"
            done
        fi
    } >"$RMQ_HOME/rabbitmq.conf"
    chmod 644 "$RMQ_HOME/rabbitmq.conf"

    cat >"$RMQ_HOME/.env" <<EOF
RMQ_IMAGE=$RMQ_IMAGE
RMQ_NODENAME=rabbit@$NODE_IP
EOF
    cp "$CURRENT_DIRECTORY/docker-compose.rabbitmq.yml" "$RMQ_HOME/docker-compose.yml"
}

start_rabbitmq() {
    log_i "Start RabbitMQ container"
    cd "$RMQ_HOME"
    docker compose up -d
    for i in {1..60}; do
        if docker exec rabbitmq rabbitmqctl -q await_startup --timeout 10 &>/dev/null; then
            log_i "RabbitMQ is running"
            return
        fi
        log_i "Wait for RabbitMQ startup ($i)"
        sleep 5
    done
    docker logs --tail 100 rabbitmq || true
    log_e "RabbitMQ did not start"
    exit 1
}

running_nodes() {
    docker exec rabbitmq rabbitmqctl -q cluster_status --formatter json 2>/dev/null |
        python3 -c 'import sys, json; print(len(json.load(sys.stdin).get("running_nodes", [])))' 2>/dev/null || echo 0
}

wait_for_cluster() {
    if [ "$NODE_COUNT" -le 1 ]; then
        return
    fi
    log_i "Wait for $NODE_COUNT running cluster nodes"
    local elapsed=0
    while [ "$elapsed" -lt "$RMQ_CLUSTER_TIMEOUT" ]; do
        local count
        count=$(running_nodes)
        if [ "$count" -ge "$NODE_COUNT" ]; then
            log_i "RabbitMQ cluster has $count running nodes"
            return
        fi
        log_i "RabbitMQ cluster has $count of $NODE_COUNT running nodes, wait 10 sec"
        sleep 10
        elapsed=$((elapsed + 10))
    done
    docker exec rabbitmq rabbitmqctl cluster_status || true
    log_e "RabbitMQ cluster did not form in ${RMQ_CLUSTER_TIMEOUT}s"
    exit 1
}

rmqctl() {
    docker exec rabbitmq rabbitmqctl "$@"
}

config_user() {
    if [ "$RMQ_NODE_INDEX" != "1" ]; then
        log_i "Users and vhost are configured on node 1"
        return
    fi
    log_i "Configure vhost $RMQ_VHOST and user $RMQ_USER"
    if ! rmqctl -q list_vhosts name | grep -qx "$RMQ_VHOST"; then
        rmqctl add_vhost "$RMQ_VHOST" --description "$RMQ_VHOST_DESCRIPTION"
    fi

    if rmqctl -q list_users | awk '{print $1}' | grep -qx "$RMQ_USER"; then
        rmqctl change_password "$RMQ_USER" "$RMQ_PASSWORD"
    else
        rmqctl add_user "$RMQ_USER" "$RMQ_PASSWORD"
    fi
    rmqctl set_user_tags "$RMQ_USER" administrator
    rmqctl set_permissions -p "$RMQ_VHOST" "$RMQ_USER" ".*" ".*" ".*"
    rmqctl set_permissions -p / "$RMQ_USER" ".*" ".*" ".*"

    if rmqctl -q list_users | awk '{print $1}' | grep -qx guest; then
        rmqctl delete_user guest
    fi

    rmqctl -q list_vhosts name
    rmqctl -q list_users
    rmqctl cluster_status
}

check_variables
wait_for_apt
install_docker
config_rabbitmq
start_rabbitmq
wait_for_cluster
config_user
log_i "RabbitMQ installed and configured"
