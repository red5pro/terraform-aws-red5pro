#!/bin/bash
######################################
# Install and configure Kafka Server
######################################
# KAFKA_ARCHIVE_URL="https://downloads.apache.org/kafka/3.8.0/kafka_2.13-3.8.0.tgz"
# KAFKA_CLUSTER_ID="kafka-id"

CURRENT_DIRECTORY=$(pwd)
packages=(ripgrep kafkacat)
kafka_log_dir="/var/log/kafka"

export DEBIAN_FRONTEND=noninteractive

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
        local install_issuse=0
        apt-get -y update --fix-missing &>/dev/null

        for index in ${!packages[*]}; do
            log_i "Install utility ${packages[$index]}"
            apt-get install -y ${packages[$index]} &>/dev/null
        done

        for index in ${!packages[*]}; do
            PKG_OK=$(dpkg-query -W --showformat='${Status}\n' ${packages[$index]} | grep "install ok installed")
            if [ -z "$PKG_OK" ]; then
                log_i "${packages[$index]} utility didn't install, didn't find MIRROR !!! "
                install_issuse=$((${install_issuse} + 1))
            else
                log_i "${packages[$index]} utility installed"
            fi
        done

        if [ ${install_issuse} -eq 0 ]; then
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
    wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg &&
        echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list
    apt-get update
    apt-get install -y java-17-amazon-corretto-jdk
}

download_kafka_archive() {
    log_i "Download Kafka archive..."
    wget -q "$KAFKA_ARCHIVE_URL"
    # wget "$KAFKA_ARCHIVE_URL"
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

install_kafka() {
    log_i "Kafka configuring..."
    tar -xzvf "${kafka_archive}" -C /usr/local/ >/dev/null 2>&1 # Extract the kafka archive without verbose output
    mv /usr/local/kafka_* /usr/local/kafka
    mkdir -p $kafka_log_dir
    if [[ -d "/usr/local/kafka" ]]; then
        # Set kafka log location to /var/log/kafka/kafka-logs
        if [[ ! -d "$kafka_log_dir/kafka-logs" ]]; then
            log_i "Kafka log directory doesn't exists, creating $kafka_log_dir/kafka-logs"
            mkdir -p $kafka_log_dir/kafka-logs
        fi
        chmod 777 -R $kafka_log_dir/kafka-logs

        kafka_config_file="/usr/local/kafka/config/kraft/server.properties"
        sed 's/log.dirs=.*/log.dirs=\/var\/log\/kafka\/kafka-logs/' -i "$kafka_config_file"
                
        # log.retention.hours
        # reduce the log retention hours from default 168 hours to 24 hours
        sed 's/log.retention.hours.*/log.retention.hours=24/' -i "$kafka_config_file"

        # log.retention.bytes
        # Set the log retention bytes to 1GB
        sed 's/#log.retention.bytes=.*$/log.retention.bytes=1073741824/' -i "$kafka_config_file"

        # log.segment.bytes
        # Set the log segment bytes to 128MB
        sed 's/#log.segment.bytes=.*$/log.segment.bytes=134217728/' -i "$kafka_config_file"

        # log.retention.check.interval.ms
        # increase the retention check interval from default 5 minutes to 15 minutes
        sed 's/log.retention.check.interval.ms.*$/log.retention.check.interval.ms=900000/' -i "$kafka_config_file"

        # Comment out the advertised.listeners configuration
        sed -i 's/^advertised.listeners/#&/' "$kafka_config_file"

        # Static configuration for kafka
        sed -i 's/broker.id=.*/broker.id=0/' "$kafka_config_file"
        sed -i 's/inter.broker.listener.name=.*/inter.broker.listener.name=BROKER/' "$kafka_config_file"
        sed -i 's/listener.security.protocol.map=.*/listener.security.protocol.map=BROKER:SASL_SSL,CONTROLLER:SASL_SSL,PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL/' "$kafka_config_file"
        # sed -i 's/controller.quorum.voters=.*/controller.quorum.voters=1/' "$kafka_config_file"
        sed -i 's/listeners=.*/listeners=BROKER:\/\/:9092,CONTROLLER:\/\/:9093/' "$kafka_config_file"

        {
            echo 'ssl.keystore.type=PEM'
            echo 'ssl.truststore.type=PEM'
            echo 'ssl.endpoint.identification.algorithm='
            echo 'sasl.enabled.mechanisms=PLAIN'
            echo 'sasl.mechanism.controller.protocol=PLAIN'
            echo 'sasl.mechanism.inter.broker.protocol=PLAIN'
            echo 'max.request.size=52428800'
            echo 'initial.broker.registration.timeout.ms=240000'
        } >> "$kafka_config_file"

        # Copy extra kafka configuration properties from /home/ubuntu/red5pro-installer/server.properties to "$kafka_config_file"
        if [[ -f "/home/ubuntu/red5pro-installer/server.properties" ]]; then
            cat /home/ubuntu/red5pro-installer/server.properties >> "$kafka_config_file"
        else
            log_e "Extra kafka configuration properties file /home/ubuntu/red5pro-installer/server.properties does not exists"
            exit 1
        fi

        log_i "Format Kafka storage with KAFKA_CLUSTER_ID"
        /usr/local/kafka/bin/kafka-storage.sh format -t "$KAFKA_CLUSTER_ID" -c "$kafka_config_file"

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

    # Set the kafka heap size to 6GB
    mkdir -p /etc/sysconfig
    echo 'KAFKA_HEAP_OPTS="-Xmx6g -Xms6g"' >> /etc/sysconfig/kafka
}

start_kafka() {
    log_i "Start Kafka service"
    systemctl restart kafka.service
    if [ "0" -eq $? ]; then
        log_i "Kafka service started!"
    else
        log_e "Kafka service didn't started!"
        log_e "Job for kafka.service failed, See systemctl status kafka.service and journalctl -xe for details."
        exit 1
    fi
}

install_pkg
install_jdk
download_kafka_archive
install_kafka
start_kafka