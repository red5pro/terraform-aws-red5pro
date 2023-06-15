#!/bin/bash

SM_IP=$1
SM_API_KEY=$2

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
    exit 1
}
log() {
    echo -n "[$(date '+%Y-%m-%d %H:%M:%S')]"
}

delete_node_group(){
    log_i "Checking active node groups ..."

    if [[ -z "$SM_IP" ]]; then
        log_e "SM_IP is not set!"
    fi
    if [[ -z "$SM_API_KEY" ]]; then
        log_e "SM_API_KEY is not set!"
    fi

    error=0
    
    NODE_GROUPS=$(curl -s "http://${SM_IP}:5080/streammanager/api/4.0/admin/nodegroup?accessToken=${SM_API_KEY}" |jq -r '.[].name')
    
    for group in $NODE_GROUPS
    do
        log_i "Deleting node group: $group"
        DELETE_NODE_GROUP=$(curl -s --location --request DELETE "http://${SM_IP}:5080/streammanager/api/4.0/admin/nodegroup/${group}?accessToken=${SM_API_KEY}")
        delete_resp=$(echo "$DELETE_NODE_GROUP" | jq -r '.name')
        
        if [[ "$delete_resp" == "$group" ]]; then
            log_i "Node group deleted successfully."
        else
            log_w "Node group was not deleted!"
            error=1
        fi
    done
    
    if [[ $error -eq 1 ]]; then
        log_e "One or more node groups was not deleted. Please check and delete Node group manualy!!!"
    fi
}

delete_node_group
