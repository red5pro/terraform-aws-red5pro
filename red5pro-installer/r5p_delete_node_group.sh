#!/bin/bash

# SM_IP="1.2.3.4"
# R5AS_AUTH_USER="user"
# R5AS_AUTH_PASS="password"

SM_IP=$1
R5AS_AUTH_USER=$2
R5AS_AUTH_PASS=$3

log_i() {
    log
    printf "\033[0;32m [INFO]  --- %s \033[0m\n" "${@}"
}
log_d() {
    log
    printf "\033[0;34m [DEBUG]  --- %s \033[0m\n" "${@}"
}
log_w() {
    log
    printf "\033[0;33m [WARN] --- %s \033[0m\n" "${@}"
}
log_e() {
    log
    printf "\033[0;31m [ERROR]  --- %s \033[0m\n" "${@}"
}
log() {
    echo -n "[$(date '+%Y-%m-%d %H:%M:%S')]"
}

check_sm_url() {
    if [ -z "$SM_IP" ]; then
        log_e "SM_IP is empty. EXIT."
        exit 1
    fi

    # Check HTTPS
    https_response=$(curl -s -o /dev/null -w "%{http_code}" --insecure "https://$SM_IP/as/v1/admin/healthz")
    if [ "$https_response" -eq 200 ]; then
        SM_URL="https://$SM_IP"
        log_i "SM URL is accessible over HTTPS: $SM_URL"
    fi

    # Check HTTP
    http_response=$(curl -s -o /dev/null -w "%{http_code}" "http://$SM_IP/as/v1/admin/healthz")
    if [ "$http_response" -eq 200 ]; then
        SM_URL="http://$SM_IP"
        log_i "SM URL is accessible over HTTP: $SM_URL"
    fi

    if [ -z "$SM_URL" ]; then
        log_e "SM URL is not accessible. EXIT."
        exit 1
    fi
}

create_jwT_token() {
    log_i "Creating JWT token..."
    USER_AND_PASSWORD_IN_BASE64=$(echo -n "$R5AS_AUTH_USER:$R5AS_AUTH_PASS" | base64)

    for i in {1..5}; do
        JWT_TOKEN_JSON=$(curl --insecure -s -X 'PUT' "$SM_URL/as/v1/auth/login" -H 'accept: application/json' -H "Authorization: Basic $USER_AND_PASSWORD_IN_BASE64" -H 'Content-Length: 0')
        JWT_TOKEN=$(jq -r '.token' <<<"$JWT_TOKEN_JSON")

        if [ -z "$JWT_TOKEN" ] || [ "$JWT_TOKEN" == "null" ]; then
            log_w "JWT token was not created! - Attempt $i"
            log_d "JWT_TOKEN_JSON: $JWT_TOKEN_JSON"
        else
            log_i "JWT token created successfully."
            break
        fi

        if [ "$i" -eq 5 ]; then
            log_e "JWT token was not created!!! EXIT..."
            exit 1
        fi
        sleep 5
    done
}

delete_node_group(){
    log_i "Checking active node groups ..."
    error=0
    NODE_GROUPS=$(curl --insecure -s -H "Content-Type: application/json" -H "Authorization: Bearer ${JWT_TOKEN}" "$SM_URL/as/v1/admin/nodegroup" | jq -r '.[]')
    
    for group in $NODE_GROUPS
    do
        log_i "Deleting node group: $group"
        DELETE_NODE_GROUP=$(curl --insecure -s -o /dev/null -w "%{http_code}" --location --request DELETE "$SM_URL/as/v1/admin/nodegroup/${group}" --header "Authorization: Bearer ${JWT_TOKEN}" --header 'Content-Type: application/json')
        if [[ "$DELETE_NODE_GROUP" == "200" ]]; then
            log_i "Node group deleted successfully."
        else
            log_e "Node group was not deleted!"
            error=1
        fi
    done
    
    if [[ $error -eq 1 ]]; then
        log_e "One or more node groups was not deleted. Please check and delete Node group manualy using SM2.0 API!!!"
        exit 1
    fi
}

check_sm_url
create_jwT_token
delete_node_group
