#!/bin/bash
############################################################################################################
# Before start this script you need copy red5pro-server-build.zip into the same folder with this script!!!
############################################################################################################
export DEBIAN_FRONTEND=noninteractive

RED5_HOME="/usr/local/red5pro"
CURRENT_DIRECTORY=$(pwd)
TEMP_FOLDER="$CURRENT_DIRECTORY/tmp"

PACKAGES_DEFAULT=(jsvc ntp git unzip libvdpau1 iftop nano software-properties-common sysstat)
PACKAGES_1604=(default-jre libva1 libva-drm1 libva-x11-1)
PACKAGES_1804=(libva2 libva-drm2 libva-x11-2)
PACKAGES_2004=(libva2 libva-drm2 libva-x11-2)
PACKAGES_2204=(libva2 libva-drm2 libva-x11-2 libde265-0)
JDK_8=(openjdk-8-jre-headless)
JDK_11=(openjdk-11-jdk)
JDK_21=(openjdk-21-jdk)

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

check_linux_and_java_versions() {
    log_i "Checking the required JAVA version..."
    sleep 1

    red5pro_service_file="$RED5_HOME/red5pro.service"

    if [ ! -f "$red5pro_service_file" ]; then
        log_e "Service file not found: $red5pro_service_file"
        exit 1
    fi

    if grep -q "java-8-openjdk-amd64" "$red5pro_service_file"; then
        log_i "Found required JAVA version: java-8-openjdk-amd64"
        jdk_version="jdk8"
    else
        if grep -q "java-11-openjdk-amd64" "$red5pro_service_file"; then
            log_i "Found required JAVA version: java-11-openjdk-amd64"
            jdk_version="jdk11"
        elif grep -q "java-21-openjdk-amd64" "$red5pro_service_file"; then
            log_i "Found required JAVA version: java-21-openjdk-amd64"
            jdk_version="jdk21"
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
            exit 1
        else
            PACKAGES=("${PACKAGES_1604[@]}")
        fi
        ;;
    18.04)
        case "${jdk_version}" in
        jdk8) PACKAGES=("${PACKAGES_1804[@]}" "${JDK_8[@]}") ;;
        jdk11) PACKAGES=("${PACKAGES_1804[@]}" "${JDK_11[@]}") ;;
        jdk21) PACKAGES=("${PACKAGES_1804[@]}" "${JDK_21[@]}") ;;
        *)
            log_e "JDK version is not supported $jdk_version"
            exit 1
            ;;
        esac
        ;;
    20.04)
        case "${jdk_version}" in
        jdk8) PACKAGES=("${PACKAGES_2004[@]}" "${JDK_8[@]}") ;;
        jdk11) PACKAGES=("${PACKAGES_2004[@]}" "${JDK_11[@]}") ;;
        jdk21) PACKAGES=("${PACKAGES_2004[@]}" "${JDK_21[@]}") ;;
        *)
            log_e "JDK version is not supported $jdk_version"
            exit 1
            ;;
        esac
        ;;
    22.04)
        case "${jdk_version}" in
        jdk8) PACKAGES=("${PACKAGES_2204[@]}" "${JDK_8[@]}") ;;
        jdk11) PACKAGES=("${PACKAGES_2204[@]}" "${JDK_11[@]}") ;;
        jdk21)
            PACKAGES=("${PACKAGES_2204[@]}" "${JDK_21[@]}")
            log_i "Add libde265 repository"
            if ! add-apt-repository -y ppa:strukturag/libde265; then
                log_e "Failed to add libde265 repository"
                exit 1
            fi
            ;;
        *)
            log_e "JDK version is not supported $jdk_version"
            exit 1
            ;;
        esac
        ;;
    *)
        log_e "Linux version is not supported $DISTRIB_RELEASE"
        exit 1
        ;;
    esac
}

install_pkg() {
    for i in {1..20}; do
        local install_issue=0
        
        # Add retry logic for apt-get update
        update_attempts=0
        while [ $update_attempts -lt 3 ]; do
            log_i "Running apt-get update (attempt $((update_attempts + 1)) of 3)..."
            if apt-get -y update --fix-missing &>/dev/null; then
                log_i "apt-get update successful"
                break
            else
                log_w "apt-get update failed, retrying..."
                update_attempts=$((update_attempts + 1))
                if [ $update_attempts -lt 3 ]; then
                    sleep $((10 * update_attempts))
                fi
            fi
        done
        
        if [ $update_attempts -ge 3 ]; then
            log_e "apt-get update failed after 3 attempts"
            exit 1
        fi

        for index in ${!PACKAGES[*]}; do
            log_i "Install pkg ${PACKAGES[$index]}"
            # Add retry logic for individual package installation
            pkg_attempts=0
            while [ $pkg_attempts -lt 3 ]; do
                if apt-get install -y "${PACKAGES[$index]}" &>/dev/null; then
                    break
                else
                    log_w "Failed to install ${PACKAGES[$index]} on attempt $((pkg_attempts + 1))"
                    pkg_attempts=$((pkg_attempts + 1))
                    if [ $pkg_attempts -lt 3 ]; then
                        sleep $((5 * pkg_attempts))
                    fi
                fi
            done
        done

        for index in ${!PACKAGES[*]}; do
            PKG_OK=$(dpkg-query -W --showformat='${Status}\n' "${PACKAGES[$index]}" | grep "install ok installed")
            if [ -z "$PKG_OK" ]; then
                log_i "${PACKAGES[$index]} pkg is not installed"
                install_issue=$(($install_issue + 1))
            else
                log_i "${PACKAGES[$index]} pkg is installed"
            fi
        done

        if [ $install_issue -eq 0 ]; then
            break
        fi
        if [ $i -ge 20 ]; then
            log_e "Failed to install packages"
            exit 1
        fi
        # Increase sleep time with each iteration to handle rate limiting
        sleep $((10 + i * 2))
    done
}

install_red5pro() {
    log_i "Install RED5PRO"
    
    # Check if red5pro-server zip file exists
    RED5ARCHIVE=""
    for zipfile in "$CURRENT_DIRECTORY"/red5pro-server-*.zip; do
        if [ -f "$zipfile" ]; then
            RED5ARCHIVE=$(basename "$zipfile")
            break
        fi
    done
    
    if [ -z "$RED5ARCHIVE" ]; then
        log_e "No red5pro-server-*.zip file found in $CURRENT_DIRECTORY"
        exit 1
    fi
    
    # Create temp folder if it doesn't exist
    if [ ! -d "$TEMP_FOLDER" ]; then
        mkdir -p "$TEMP_FOLDER"
    fi
    
    if ! unzip -q "$CURRENT_DIRECTORY/$RED5ARCHIVE" -d "$TEMP_FOLDER/"; then
        log_e "Failed to extract zip. Possible invalid archive"
        if [ -d "$TEMP_FOLDER" ]; then
            find "$TEMP_FOLDER" -mindepth 1 -delete
        fi
        exit 1
    fi
    
    # CHECKING UNPACKED ARCHIVE FILES STRUCTURE
    local count
    count=$(find "$TEMP_FOLDER" -maxdepth 1 -type d | wc -l)
    
    if [ $count -gt 2 ]; then
        if [ ! -d "$RED5_HOME" ]; then
            mkdir -p "$RED5_HOME"
        fi
        log_i "Single level archive -> top level manual zip"
        if ! mv "$TEMP_FOLDER"/* "$RED5_HOME" 2>/dev/null; then
            log_e "Failed to move files to $RED5_HOME"
            exit 1
        fi
        
    else
        log_i "Two-level archive"
        if ! ls "$TEMP_FOLDER"/red5pro* 1> /dev/null 2>&1; then
            log_e "No red5pro directory found in archive"
            exit 1
        fi
        if ! mv "$TEMP_FOLDER"/red5pro* "$RED5_HOME" 2>/dev/null; then
            log_e "Failed to move red5pro files to $RED5_HOME"
            exit 1
        fi
    fi
    
    log_i "Install DEVELOP license key"
    echo "$LICENSE_KEY_DEV" > "$RED5_HOME/LICENSE.KEY" #DEV
    sed -i -e "/\[Service\]/a Environment=license_host=${LICENSE_HOST_DEV}" "$RED5_HOME/red5pro.service"
}

install_red5pro_service(){
    log_i "Install Red5Pro service file"
       
    cp "$RED5_HOME/red5pro.service" /lib/systemd/system/red5pro.service
        
    systemctl daemon-reload
    systemctl enable red5pro.service
}

install_ffmpeg() {
    log_i "Installing FFmpeg 8+ from UbuntuHandbook PPA"
    # Add FFmpeg 8 PPA
    if ! add-apt-repository -y ppa:ubuntuhandbook1/ffmpeg8; then
        log_e "Failed to add FFmpeg 8 PPA"
        exit 1
    fi
    
    PACKAGES=(ffmpeg)
    install_pkg

    if command -v ffmpeg &> /dev/null; then
        FFMPEG_VERSION=$(ffmpeg -version 2>&1 | head -1)
        log_i "✓ FFmpeg installed successfully: $FFMPEG_VERSION"
    else
        log_e "FFmpeg installation failed"
        exit 1
    fi
}

linux_optimization() {
    log_i "Start Linux optimization"

    echo 'fs.file-max = 1000000' | tee -a /etc/sysctl.conf
    echo 'kernel.pid_max = 999999' | tee -a /etc/sysctl.conf
    echo 'kernel.threads-max = 999999' | tee -a /etc/sysctl.conf
    echo 'vm.max_map_count = 1999999' | tee -a /etc/sysctl.conf
    echo 'root soft nofile 1000000' | tee -a /etc/security/limits.conf
    echo 'root hard nofile 1000000' | tee -a /etc/security/limits.conf
    echo 'ubuntu soft nofile 1000000' | tee -a /etc/security/limits.conf
    echo 'ubuntu hard nofile 1000000' | tee -a /etc/security/limits.conf
    echo 'session required pam_limits.so' | tee -a /etc/pam.d/common-session
    ulimit -n 1000000
    sysctl -p
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
        log_i "Red5Pro WEBAPP API - disable"
        if [ -d "$RED5_HOME/webapps/api" ]; then
            rm -r $RED5_HOME/webapps/api
        fi
    fi
}

log_i "Check if apt is locked"
if command -v pgrep &>/dev/null; then
    while pgrep -f "apt|dpkg" >/dev/null; do
        echo "apt is locked, wait 5 sec"
        sleep 5
    done
elif command -v ps &>/dev/null; then
    while ps aux | grep -E '[a]pt|[d]pkg' >/dev/null; do
        echo "apt is locked, wait 5 sec"
        sleep 5
    done
else
    log_i "Neither pgrep nor ps available, skipping apt lock check"
fi

log_i "Start basic Red5 Pro server installation..."

PACKAGES=("${PACKAGES_DEFAULT[@]}")
install_pkg
install_red5pro
check_linux_and_java_versions
install_pkg
install_red5pro_service
install_ffmpeg
linux_optimization
config_red5pro_api