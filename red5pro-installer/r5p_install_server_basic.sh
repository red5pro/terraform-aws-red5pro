#!/bin/bash
############################################################################################################
# Before start this script you need copy red5pro-server-build.zip into the same folder with this script!!!
############################################################################################################

RED5_HOME="/usr/local/red5pro"
CURRENT_DIRECTORY=$(pwd)
TEMP_FOLDER="$CURRENT_DIRECTORY/tmp"

PACKAGES_DEFAULT=(jsvc ntp git unzip libvdpau1 ffmpeg)
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
        22.04)
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
    for i in {1..20};
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
                log_i "${PACKAGES[$index]} utility didn't install. Will try again"
                install_issuse=$(($install_issuse+1));
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

install_red5pro(){
    log_i "Install RED5PRO"
        
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
    
    if [ -n "$LICENSE_KEY" ]; then
        if [ -f "$RED5_HOME/LICENSE.KEY" ]; then
            rm $RED5_HOME/LICENSE.KEY
            echo "$LICENSE_KEY" > $RED5_HOME/LICENSE.KEY
        else
            echo "$LICENSE_KEY" > $RED5_HOME/LICENSE.KEY
        fi
    fi
}

install_red5pro_service(){
    log_i "Install Red5Pro service file"
       
    cp "$RED5_HOME/red5pro.service" /lib/systemd/system/red5pro.service
        
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
}

config_red5pro_api(){
    if [[ "$NODE_API_ENABLE" == "true" ]]; then
        log_i "Red5Pro WEBAPP API - enable"

        if [ -z "$NODE_API_KEY" ]; then
            log_e "Parameter NODE_API_KEY is empty. EXIT."
            exit 1
        fi
        local token_pattern='security.accessToken=.*'
        local token_new="security.accessToken=${NODE_API_KEY}"
        
        sed -i -e "s|$token_pattern|$token_new|" "$RED5_HOME/webapps/api/WEB-INF/red5-web.properties"
        echo " " >> $RED5_HOME/webapps/api/WEB-INF/security/hosts.txt
        echo "*" >> $RED5_HOME/webapps/api/WEB-INF/security/hosts.txt
    else
        log_d "Red5Pro WEBAPP API - disable"
        if [ -d "$RED5_HOME/webapps/api" ]; then
            rm -r $RED5_HOME/webapps/api
        fi
    fi
}

if command -v flock &> /dev/null; then
    log_i "Check if apt is locked"
    while ! flock -n /var/lib/apt/lists/lock true; do 
        echo "apt is locked, wait 5 sec"
        sleep 5
    done
fi

PACKAGES=("${PACKAGES_DEFAULT[@]}")
install_pkg
install_red5pro
check_linux_and_java_versions
install_pkg
install_red5pro_service
linux_optimization
config_red5pro_api