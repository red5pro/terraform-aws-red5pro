#!/bin/bash
############################################################################################################
# Install and configure local MySQL Database
############################################################################################################

# DB_LOCAL_ENABLE=false
# DB_USER="exampleuser"
# DB_PASSWORD="examplepass"
# DB_PORT="3306"

PACKAGES=(mysql-server)

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

mysql_check_variables(){
    log_i "Check DB variables..."
    
    if [ -z "$DB_USER" ]; then
        log_w "Variable DB_USER is empty."
        var_error=1
    fi
    if [ -z "$DB_PASSWORD" ]; then
        log_w "Variable DB_PASSWORD is empty."
        var_error=1
    fi
    if [ -z "$DB_PORT" ]; then
        log_w "Variable DB_PASSWORD is empty."
        var_error=1
    fi
    if [[ "$var_error" == "1" ]]; then
        log_e "One or more variables are empty. EXIT!"
        exit 1
    fi
}

mysql_config(){
    log_i "Start MySQL DB config ..."
    log_i "Creating MySQL user ..."
    mysql -e "CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
    mysql -e "GRANT ALL PRIVILEGES ON * . * TO '${DB_USER}'@'%';"

    log_i "Creating DB cluster ..."
    mysql -u $DB_USER -p${DB_PASSWORD} -e "CREATE DATABASE cluster;"

    mysql_config="/etc/mysql/mysql.conf.d/mysqld.cnf"
    log_i "MYSQL extra configuration in config file: $mysql_config"

    if [ ! -f "$mysql_config" ]; then
        log_i "MySQL configuration script was not found: $mysql_config. Exit."
        exit 1
    fi

    {
        echo 'bind-address = 0.0.0.0'
        echo 'max_connections = 100000'
        echo "port = $DB_PORT" 
    } >> $mysql_config
}

mysql_restart_service(){
    log_i "STARTING MYSQL SERVICE"
    systemctl restart mysql
    
    if [ "0" -eq $? ]; then
        log_i "MYSQL SERVICE started!"
    else
        log_e "MYSQL SERVICE didn't start!!!"
        exit 1
    fi
}

if [[ "$DB_LOCAL_ENABLE" == true ]]; then
    export LC_ALL="en_US.UTF-8"
    export LC_CTYPE="en_US.UTF-8"
    install_pkg
    mysql_restart_service
    mysql_check_variables
    mysql_config
    mysql_restart_service
else
    log_i "SKIP Local MySQL DB installation."
fi