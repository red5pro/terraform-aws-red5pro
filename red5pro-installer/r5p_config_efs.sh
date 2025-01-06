#!/bin/bash
############################################################################################################
# Install and configure EFS (NFS client)
############################################################################################################

# NODE_EFS_ENABLE="true"
# NODE_EFS_DNS_NAME=""
# NODE_EFS_MOUNT_POINT="/usr/local/webapps/live/streams"

PACKAGES=(nfs-common)

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

check_variables(){
    log_i "Check EFS DNS variables..."
    
    if [ -z "$NODE_EFS_DNS_NAME" ]; then
        log_w "Variable NODE_EFS_DNS_NAME is empty."
        var_error=1
    fi
    if [ -z "$NODE_EFS_MOUNT_POINT" ]; then
        log_w "Variable NODE_EFS_MOUNT_POINT is empty."
        var_error=1
    fi

    if [[ "$var_error" == "1" ]]; then
        log_e "One or more variables are empty. EXIT!"
        exit 1
    fi
}

configure_efs_mount(){

    if [ -d "$NODE_EFS_MOUNT_POINT" ]; then
        log_i "Directory $NODE_EFS_MOUNT_POINT already exist"
    else
        log_i "Directory $NODE_EFS_MOUNT_POINT does not exist, creating directory"
        mkdir -p "$NODE_EFS_MOUNT_POINT"
    fi

    log_i "Configuring EFS mount.."

    mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport "$NODE_EFS_DNS_NAME":/ "$NODE_EFS_MOUNT_POINT"
    if [ $? == 0 ]; then
        log_i "Mount successfull on directory $NODE_EFS_MOUNT_POINT"
    else
        log_e "Mounting on directory $NODE_EFS_MOUNT_POINT does not succeed! EXIT."
        exit 1
    fi

    log_i "Updating /etc/fstab to mount EFS automatically using NFS"
    echo "$NODE_EFS_DNS_NAME:/ $NODE_EFS_MOUNT_POINT nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
}

if [[ "$NODE_EFS_ENABLE" == "true" ]]; then
    check_variables
    install_pkg
    configure_efs_mount
fi
