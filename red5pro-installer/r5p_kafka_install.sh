#!/bin/bash
######################################
# Install and configure Kafka Server
######################################
# KAFKA_ARCHIVE_URL="https://downloads.apache.org/kafka/3.8.0/kafka_2.13-3.8.0.tgz"
# KAFKA_CLUSTER_ID="kafka-id"

set -euo pipefail

CURRENT_DIRECTORY=$(pwd)
packages=(ripgrep kafkacat)
kafka_log_dir="/var/log/kafka"

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

install_pkg() {
    for i in {1..5}; do
        local install_issue=0
        apt-get -y update --fix-missing || true

        for index in ${!packages[*]}; do
            log_i "Install utility ${packages[$index]}"
            apt-get install -y ${packages[$index]} || true
        done

        for index in ${!packages[*]}; do
            local PKG_OK
            PKG_OK=$(dpkg-query -W --showformat='${Status}\n' ${packages[$index]} | grep "install ok installed" || true)
            if [ -z "$PKG_OK" ]; then
                log_i "${packages[$index]} utility didn't install, didn't find MIRROR !!! "
                install_issue=$((install_issue + 1))
            else
                log_i "${packages[$index]} utility installed"
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

install_jdk() {
    for attempt in {1..5}; do
        if wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg &&
            echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list &&
            apt-get update &&
            apt-get install -y java-17-amazon-corretto-jdk; then
            return 0
        fi

        log_w "JDK installation attempt ${attempt} failed, retrying in 20s..."
        sleep 20
    done

    log_e "Failed to install JDK after 5 attempts. Exiting."
    exit 1
}

check_memory_requirements() {
    local total_memory_mb
    total_memory_mb=$(free -m | awk '/^Mem:/{print $2}') # Value in MB

    if [ "$total_memory_mb" -lt 8192 ]; then
        log_e "Kafka requires at least 8 GB of memory. Found ${total_memory_mb} MB. Exiting."
        exit 1
    fi
}

check_not_already_installed() {
    if [[ -d "/usr/local/kafka" ]]; then
        log_e "/usr/local/kafka already exists; this installer is meant to run once against a fresh instance. Exiting."
        exit 1
    fi
}

force_apt_ipv4() {
    log_i "Forcing apt to use IPv4 (avoids slow/failed IPv6 attempts to Ubuntu mirrors on networks without IPv6 routing)"
    echo 'Acquire::ForceIPv4 "true";' >/etc/apt/apt.conf.d/99force-ipv4
}

wait_for_dns() {
    log_i "Waiting for DNS resolution to become available"
    local timeout=90
    local elapsed=0
    while ! getent hosts archive.ubuntu.com &>/dev/null; do
        if [ "$elapsed" -ge "$timeout" ]; then
            log_w "DNS still not resolving after ${timeout}s, proceeding anyway"
            break
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    log_i "DNS resolution check finished after ${elapsed}s"
}

download_kafka_archive() {
    log_i "Download Kafka archive: $KAFKA_ARCHIVE_URL"
    local downloaded=0
    for attempt in {1..5}; do
        if wget "$KAFKA_ARCHIVE_URL"; then
            downloaded=1
            break
        fi
        log_w "Kafka archive download attempt ${attempt} failed, retrying in 15s..."
        rm -f kafka_*.tgz
        sleep 15
    done
    if [ "$downloaded" -eq 0 ]; then
        log_e "Failed to download Kafka archive from $KAFKA_ARCHIVE_URL after 5 attempts. Exiting."
        exit 1
    fi
    if ls kafka_*.tgz 1>/dev/null 2>&1; then
        log_i "File matching kafka_*.tgz exists."
        kafka_archive=$(ls kafka_*.tgz | xargs -n 1 basename)
        log_i "Kafka archive: $kafka_archive"
    else
        log_e "No file matching kafka_*.tgz found. Exiting."
        ls -lo
        exit 1
    fi
}

set_config() {
    local key="$1"
    local value="$2"

    log_i "Setting configuration: $key=$value"

    local escaped_value
    escaped_value=$(printf '%s' "$value" | sed -e 's/[\&|]/\\&/g')

    if grep -q "^[#]*\s*$key=" "$kafka_config_file"; then
        sed -i "s|^[#]*\s*$key=.*|$key=$escaped_value|" "$kafka_config_file"
    else
        echo "$key=$value" >>"$kafka_config_file"
    fi
}

install_kafka() {
    log_i "Kafka configuring..."

    if ! tar -xzvf "${kafka_archive}" -C /usr/local/ >/dev/null 2>&1; then # Extract the kafka archive without verbose output
        log_e "Failed to extract Kafka archive ${kafka_archive}. Exiting."
        exit 1
    fi

    if ! mv /usr/local/kafka_* /usr/local/kafka; then
        log_e "Failed to move extracted Kafka directory to /usr/local/kafka. Exiting."
        exit 1
    fi

    mkdir -p $kafka_log_dir
    if [[ -d "/usr/local/kafka" ]]; then
        # Set kafka log location to /var/log/kafka/kafka-logs
        if [[ ! -d "$kafka_log_dir/kafka-logs" ]]; then
            log_i "Kafka log directory doesn't exists, creating $kafka_log_dir/kafka-logs"
            mkdir -p $kafka_log_dir/kafka-logs
        fi

        if ! id -u kafka &>/dev/null; then
            log_i "Creating dedicated system user 'kafka'"
            useradd --system --no-create-home --shell /usr/sbin/nologin kafka
        fi

        local kafka_config_file="/usr/local/kafka/config/kraft/server.properties"

        log_i "Setting up Kafka configuration file: $kafka_config_file"

        # Set Kafka log directory to /var/log/kafka/kafka-logs
        set_config log.dirs "/var/log/kafka/kafka-logs"

        # Comment out the advertised.listeners setting. It will be copied from ${CURRENT_DIRECTORY}/server.properties.
        sed -i 's/^advertised.listeners/#&/' "$kafka_config_file"

        # Set the listeners to BROKER and CONTROLLER
        set_config listeners "BROKER://:9092,CONTROLLER://:9093"

        # Replication and ISR
        set_config offsets.topic.replication.factor 1
        set_config group.initial.rebalance.delay.ms 0
        set_config transaction.state.log.min.isr 1
        set_config transaction.state.log.replication.factor 1

        # Retention settings
        set_config transactional.id.expiration.ms 3600000
        set_config offsets.retention.minutes 2880
        set_config log.retention.hours 24
        set_config log.retention.bytes 1073741824

        # Replica settings
        set_config replica.lag.time.max.ms 10000
        set_config replica.socket.timeout.ms 3000

        # Log segment configuration
        set_config log.segment.bytes 16777216
        set_config log.segment.ms 30000

        # Log cleanup
        set_config log.cleanup.interval.ms 10000
        set_config log.delete.delay.ms 1000

        # Listener and protocol settings
        set_config inter.broker.listener.name BROKER
        set_config listener.security.protocol.map "BROKER:SASL_SSL,CONTROLLER:SASL_SSL,PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL"

        # SSL/SASL settings
        set_config ssl.keystore.type PEM
        set_config ssl.truststore.type PEM
        set_config ssl.endpoint.identification.algorithm ""
        set_config sasl.enabled.mechanisms PLAIN
        set_config sasl.mechanism.controller.protocol PLAIN
        set_config sasl.mechanism.inter.broker.protocol PLAIN

        # Broker settings
        set_config max.request.size 52428800
        set_config initial.broker.registration.timeout.ms 240000

        # Copy extra kafka configuration properties from ${CURRENT_DIRECTORY}/server.properties to "$kafka_config_file"
        if [[ -f "${CURRENT_DIRECTORY}/server.properties" ]]; then
            cat "${CURRENT_DIRECTORY}/server.properties" >>"$kafka_config_file"
        else
            log_e "Extra kafka configuration properties file ${CURRENT_DIRECTORY}/server.properties does not exists"
            exit 1
        fi

        log_i "Format Kafka storage with KAFKA_CLUSTER_ID"
        if ! /usr/local/kafka/bin/kafka-storage.sh format -t "$KAFKA_CLUSTER_ID" -c "$kafka_config_file"; then
            log_e "kafka-storage.sh format failed. Exiting."
            exit 1
        fi

        log_i "Restricting ownership/permissions of Kafka install and data to the 'kafka' user"
        chown -R kafka:kafka /usr/local/kafka "$kafka_log_dir"
        chmod -R 750 "$kafka_log_dir"
        chmod 600 "$kafka_config_file"

    else
        log_e "Kafka server does not exists at path /usr/local/kafka"
        exit 1
    fi

    if [[ -f "${CURRENT_DIRECTORY}/kafka.service" ]]; then
        log_i "Kafka service file exists, configuring..."
        cp "${CURRENT_DIRECTORY}/kafka.service" /etc/systemd/system/kafka.service
        systemctl daemon-reload
        systemctl enable kafka.service
    else
        log_e "Kafka service file does not exists"
        exit 1
    fi

    # Set Kafka heap size to 6GB
    mkdir -p /etc/sysconfig
    echo 'KAFKA_HEAP_OPTS="-Xmx6g -Xms6g"' >/etc/sysconfig/kafka
    log_i "Kafka heap size set to 6 GB"
}

start_kafka() {
    log_i "Start Kafka service"
    if systemctl restart kafka.service; then
        log_i "Kafka service started!"
    else
        log_e "Kafka service didn't started!"
        log_e "Job for kafka.service failed, See systemctl status kafka.service and journalctl -xe for details."
        exit 1
    fi
}

check_not_already_installed
check_memory_requirements

# Use Google DNS instead of the default VPC resolver, which can be slow or
# unresponsive right after boot and stall apt/curl for several minutes.
log_i "Modify DNS servers in systemd-resolved"
echo "DNS=8.8.8.8 8.8.4.4" >>/etc/systemd/resolved.conf
echo "FallbackDNS=2001:4860:4860::8888 2001:4860:4860::8844" >>/etc/systemd/resolved.conf
systemctl restart systemd-resolved

wait_for_dns
force_apt_ipv4
install_pkg
install_jdk
download_kafka_archive
install_kafka
start_kafka
