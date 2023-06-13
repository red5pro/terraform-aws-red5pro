#!/bin/bash
############################################################################################################
# Before start this script you need copy red5pro-server-build.zip into the same folder with this script!!!
############################################################################################################

RED5_HOME="/usr/local/red5pro"
CURRENT_DIRECTORY=$(pwd)
TEMP_FOLDER="$CURRENT_DIRECTORY/tmp"

PACKAGES_DEFAULT=(jsvc ntp git unzip libvdpau1 mysql-client)
PACKAGES_1604=(default-jre libva1 libva-drm1 libva-x11-1)
PACKAGES_1804=(libva2 libva-drm2 libva-x11-2)
PACKAGES_2004=(libva2 libva-drm2 libva-x11-2)
JDK_8=(openjdk-8-jre-headless)
JDK_11=(openjdk-11-jdk)

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

check_linux_and_java_versions(){
    log_i "Checking the required JAVA version..."
    sleep 1

    red5pro_service_file="$RED5_HOME/red5pro.service"
    
    if grep -q "java-8-openjdk-amd64" $red5pro_service_file ; then
        log_i "Found required JAVA version: java-8-openjdk-amd64"
        jdk_version="jdk8"
    else
        if grep -q "java-11-openjdk-amd64" $red5pro_service_file ; then
            log_i "Found required JAVA version: java-11-openjdk-amd64"
            jdk_version="jdk11"
        else
            log_e "Not found JAVA version in the file $red5pro_service_file"
            exit 1
        fi
    fi
    
    . /etc/lsb-release
    log_i "Linux version: Ubuntu $DISTRIB_RELEASE"
    sleep 1

    case "${DISTRIB_RELEASE}" in
        16.04)
            if [[ $jdk_version == "jdk11" ]]; then
                log_e "Ubuntu 16.04 is not supporting Java version 11. Please use Ubuntu 18.04 or higher!!!"
                pause
            else
                PACKAGES=("${PACKAGES_1604[@]}")
            fi
        ;;
        18.04)
            case "${jdk_version}" in
                jdk8) PACKAGES=("${PACKAGES_1804[@]}" "${JDK_8[@]}") ;;
                jdk11) PACKAGES=("${PACKAGES_1804[@]}" "${JDK_11[@]}") ;;
                *) log_e "JDK version is not supported $jdk_version"; pause ;;
            esac
        ;;
        20.04)
            case "${jdk_version}" in
                jdk8) PACKAGES=("${PACKAGES_2004[@]}" "${JDK_8[@]}") ;;
                jdk11) PACKAGES=("${PACKAGES_2004[@]}" "${JDK_11[@]}") ;;
                *) log_e "JDK version is not supported $jdk_version"; pause ;;
            esac
        ;;
        *) log_e "Linux version is not supported $DISTRIB_RELEASE"; pause ;;
    esac
}

install_pkg(){
    for i in {1..5};
    do
        
        local install_issuse=0;
        apt-get -y update --fix-missing &> /dev/null
        
        for index in ${!PACKAGES[*]}
        do
            log_i "Install utility ${PACKAGES[$index]}"
            apt-get install -y ${PACKAGES[$index]} &> /dev/null
        done
        
        for index in ${!PACKAGES[*]}
        do
            PKG_OK=$(dpkg-query -W --showformat='${Status}\n' ${PACKAGES[$index]}|grep "install ok installed")
            if [ -z "$PKG_OK" ]; then
                log_i "${PACKAGES[$index]} utility didn't install, didn't find MIRROR !!! "
                install_issuse=$(($install_issuse+1));
            else
                log_i "${PACKAGES[$index]} utility installed"
            fi
        done
        
        if [ $install_issuse -eq 0 ]; then
            break
        fi
        if [ $i -ge 5 ]; then
            log_e "Something wrong with packages installation!!! Exit."
            exit 1
        fi
        sleep 20
    done
}

install_red5pro(){
    log_i "Install RED5PRO"
    
    if [ -z "$LICENSE_KEY" ]; then
        log_w "Variable LICENSE_KEY is empty."
        exit 1
    fi
    
    RED5ARCHIVE=$(ls $CURRENT_DIRECTORY/red5pro-server-*.zip | xargs -n 1 basename);
    
    if ! unzip -q $RED5ARCHIVE -d $TEMP_FOLDER/; then
        log_e "Failed to extract zip. Possible invalid archive"
        rm -r $TEMP_FOLDER/*
        exit 1
    fi
    
    # SHECKING UNPACKED ARCHIVE FILES STRUCTURE
    local count
    count=$(find $TEMP_FOLDER -maxdepth 1 -type d | wc -l)
    
    if [ $count -gt 2 ]; then
        if [ ! -d "$RED5_HOME" ]; then
            mkdir -p $RED5_HOME
        fi
        log_i "Single level archive -> top level manual zip"
        mv $TEMP_FOLDER/* $RED5_HOME
        
    else
        log_i "Two-level archive"
        mv $TEMP_FOLDER/red5pro* $RED5_HOME
    fi
    
    if [ -f "$RED5_HOME/LICENSE.KEY" ]; then
        rm $RED5_HOME/LICENSE.KEY
        echo "$LICENSE_KEY" > $RED5_HOME/LICENSE.KEY
    else
        echo "$LICENSE_KEY" > $RED5_HOME/LICENSE.KEY
    fi
}

test_set_mem(){
    total_memory_mb=$(free -m|awk '/^Mem:/{print $2}') # Value in Mb
    total_memory=$((total_memory_mb/1024)); # Value in Gb

    available_memory_mb=$(free -m|awk '/^Mem:/{print $7}') # Value in Mb
    available_memory=$((available_memory_mb/1024)); # Value in Gb

    if [[ "$available_memory" -le 1 ]]; then
        log_e "Minimum 2 GB server memory!!! Exit."
        exit 1
    elif [[ "$available_memory" -eq 2 ]]; then
        JVM_MEMORY=1;
    elif [[ "$available_memory" -gt 2 && "$available_memory" -le 4 ]]; then
        JVM_MEMORY=2;
    elif [[ "$available_memory" -gt 4 && "$available_memory" -le 8 ]]; then
        JVM_MEMORY=$((available_memory-2));
    elif [[ "$available_memory" -gt 8 && "$available_memory" -le 12 ]]; then
        JVM_MEMORY=$((available_memory-3));
    elif [[ "$available_memory" -gt 12 && "$available_memory" -le 20 ]]; then
        JVM_MEMORY=$((available_memory-4));
    elif [[ "$available_memory" -gt 20 && "$available_memory" -le 30 ]]; then
        JVM_MEMORY=$((available_memory-5));
    elif [[ "$available_memory" -gt 30 && "$available_memory" -le 40 ]]; then
        JVM_MEMORY=$((total_memory-6));
    else
        JVM_MEMORY=$((total_memory-8));
    fi
    log_i "Memory setting: TOTAL: ${total_memory_mb}Mb, EVALIABLE: ${available_memory_mb}Mb, JVM: ${JVM_MEMORY}Gb"
}

install_red5pro_service(){
    log_i "Install Red5Pro service file"
    
    test_set_mem
    
    cp "$RED5_HOME/red5pro.service" /lib/systemd/system/red5pro.service
    
    local service_memory_pattern='-Xms2g -Xmx2g'
    local service_memory_new="-Xms${JVM_MEMORY}g -Xmx${JVM_MEMORY}g"
    sudo sed -i -e "s|$service_memory_pattern|$service_memory_new|" "/lib/systemd/system/red5pro.service"
    
    systemctl daemon-reload
    systemctl enable red5pro.service
}

linux_optimization(){
    log_i "Start Linux optimization"

    echo 'fs.file-max = 1000000' | sudo tee -a /etc/sysctl.conf
    echo 'kernel.pid_max = 999999' | sudo tee -a /etc/sysctl.conf
    echo 'kernel.threads-max = 999999' | sudo tee -a /etc/sysctl.conf
    echo 'vm.max_map_count = 1999999' | sudo tee -a /etc/sysctl.conf
    echo 'root soft nofile 1000000' | sudo tee -a /etc/security/limits.conf
    echo 'root hard nofile 1000000' | sudo tee -a /etc/security/limits.conf
    echo 'ubuntu soft nofile 1000000' | sudo tee -a /etc/security/limits.conf
    echo 'ubuntu hard nofile 1000000' | sudo tee -a /etc/security/limits.conf
    echo 'session required pam_limits.so' | sudo tee -a /etc/pam.d/common-session
    ulimit -n 1000000
    sysctl -p

    local service_limitnofile_pattern='LimitNOFILE=65536'
    local service_limitnofile_new="LimitNOFILE=1000000"

    sudo sed -i -e "s|$service_limitnofile_pattern|$service_limitnofile_new|" "/lib/systemd/system/red5pro.service"
}

export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

PACKAGES=("${PACKAGES_DEFAULT[@]}")
install_pkg
install_red5pro
check_linux_and_java_versions
install_pkg
install_red5pro_service
linux_optimization