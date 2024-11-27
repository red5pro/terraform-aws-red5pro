#!/bin/bash
############################################################################################################
# Script Name: r5p_create_node_group.sh
# Description: This script creates a new Node Group in Stream Manager 2.0 and checks the states of the nodes.
# AUTHOR: Oles Prykhodko
# COMPANY: Infrared5, Inc.
# Date: 2024-11-07
############################################################################################################

# SM_URL="https://red5pro.example.com"
# R5AS_AUTH_USER="user"
# R5AS_AUTH_PASS="password"

# NODE_GROUP_REGION="us-ashburn-1"
# NODE_ENVIRONMENT="terra"
# NODE_SUBNET_NAME="red5-ci-deployments-multiregion-subnet-public"
# NODE_SECURITY_GROUP_NAME="red5-ci-deployments-multiregion-node-nsg"
# NODE_IMAGE_NAME="as-node-b3367-b290"

# ORIGINS_MIN=1
# EDGES_MIN=0
# TRANSCODERS_MIN=0
# RELAYS_MIN=0

# ORIGINS_MAX=1
# EDGES_MAX=1
# TRANSCODERS_MAX=1
# RELAYS_MAX=1

# ORIGIN_INSTANCE_TYPE="VM.Standard.E4.Flex-1-4"
# EDGE_INSTANCE_TYPE="VM.Standard.E4.Flex-1-4"
# TRANSCODER_INSTANCE_TYPE="VM.Standard.E4.Flex-1-4"
# RELAY_INSTANCE_TYPE="VM.Standard.E4.Flex-1-4"

# ORIGIN_VOLUME_SIZE="50"
# EDGE_VOLUME_SIZE="50"
# TRANSCODER_VOLUME_SIZE="50"
# RELAY_VOLUME_SIZE="50"

# PATH_TO_JSON_TEMPLATES="./nodegroup-json-templates"

# NODE_ROUND_TRIP_AUTH_ENABLE=true
# NODE_ROUNT_TRIP_AUTH_TARGET_NODES="origin,edge,transcoder" # origin,edge,transcoder,relay
# NODE_ROUND_TRIP_AUTH_HOST="rta-host.com.ua"
# NODE_ROUND_TRIP_AUTH_PORT="443"
# NODE_ROUND_TRIP_AUTH_PROTOCOL="https://"
# NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE="/validate"
# NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE="/invalidate"

# NODE_WEBHOOK_ENABLE=true
# NODE_WEBHOOK_TARGET_NODES="origin,edge,transcoder"
# NODE_WEBHOOK_ENDPOINT="https://webhook-endpoint.com.ua"

# NODE_SOCIAL_PUSHER_ENABLE=true
# NODE_SOCIAL_PUSHER_TARGET_NODES="origin,edge,transcoder"

# NODE_RESTREAMER_ENABLE=true
# NODE_RESTREAMER_TARGET_NODES="origin,edge,transcoder"
# NODE_RESTREAMER_TSINGEST=true
# NODE_RESTREAMER_IPCAM=false
# NODE_RESTREAMER_WHIP=true
# NODE_RESTREAMER_SRTINGEST=false

# Static variables for JSON templates
node_config_rta_json="$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_rta.json"
node_config_rta_json_mod="$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_rta_mod.json"
node_config_webhook_json="$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_webhooks.json"
node_config_webhook_json_mod="$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_webhooks_mod.json"
node_config_social_pusher_json="$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_social_pusher.json"
node_config_social_pusher_json_mod="$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_social_pusher_mod.json"
node_config_restreamer_json="$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_restreamer.json"
node_config_restreamer_json_mod="$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_restreamer_mod.json"

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

prepare_json_templates() {
    log_i "Preparing JSON templates for node group: $NODE_GROUP_TYPE"

    local node_env_pattern='NODE_ENVIRONMENT'
    local node_env_new="${NODE_ENVIRONMENT}"

    local node_subnet_pattern='NODE_SUBNET_NAME'
    local node_subnet_new="${NODE_SUBNET_NAME}"

    local node_security_group_pattern='NODE_SECURITY_GROUP_NAME'
    local node_security_group_new="${NODE_SECURITY_GROUP_NAME}"

    local node_image_name_pattern='NODE_IMAGE_NAME'
    local node_image_name_new="${NODE_IMAGE_NAME}"

    local node_group_region_pattern='NODE_GROUP_REGION'
    local node_group_region_new="${NODE_GROUP_REGION}"

    local origins_volume_size_pattern='ORIGIN_VOLUME_SIZE'
    local origins_volume_size_new="${ORIGIN_VOLUME_SIZE}"
    local origins_instance_type_pattern='ORIGIN_INSTANCE_TYPE'
    local origins_instance_type_new="${ORIGIN_INSTANCE_TYPE}"
    local origins_min_pattern='ORIGINS_MIN'
    local origins_min_new="${ORIGINS_MIN}"
    local origins_max_pattern='ORIGINS_MAX'
    local origins_max_new="${ORIGINS_MAX}"

    local edges_volume_size_pattern='EDGE_VOLUME_SIZE'
    local edges_volume_size_new="${EDGE_VOLUME_SIZE}"
    local edges_instance_type_pattern='EDGE_INSTANCE_TYPE'
    local edges_instance_type_new="${EDGE_INSTANCE_TYPE}"
    local edges_min_pattern='EDGES_MIN'
    local edges_min_new="${EDGES_MIN}"
    local edges_max_pattern='EDGES_MAX'
    local edges_max_new="${EDGES_MAX}"

    local transcoders_volume_size_pattern='TRANSCODER_VOLUME_SIZE'
    local transcoders_volume_size_new="${TRANSCODER_VOLUME_SIZE}"
    local transcoders_instance_type_pattern='TRANSCODER_INSTANCE_TYPE'
    local transcoders_instance_type_new="${TRANSCODER_INSTANCE_TYPE}"
    local transcoders_min_pattern='TRANSCODERS_MIN'
    local transcoders_min_new="${TRANSCODERS_MIN}"
    local transcoders_max_pattern='TRANSCODERS_MAX'
    local transcoders_max_new="${TRANSCODERS_MAX}"

    local relays_volume_size_pattern='RELAY_VOLUME_SIZE'
    local relays_volume_size_new="${RELAY_VOLUME_SIZE}"
    local relays_instance_type_pattern='RELAY_INSTANCE_TYPE'
    local relays_instance_type_new="${RELAY_INSTANCE_TYPE}"
    local relays_min_pattern='RELAYS_MIN'
    local relays_min_new="${RELAYS_MIN}"
    local relays_max_pattern='RELAYS_MAX'
    local relays_max_new="${RELAYS_MAX}"

    sed -e "s|$node_env_pattern|$node_env_new|" \
        -e "s|$node_subnet_pattern|$node_subnet_new|" \
        -e "s|$node_security_group_pattern|$node_security_group_new|" \
        -e "s|$node_image_name_pattern|$node_image_name_new|" \
        -e "s|$node_group_region_pattern|$node_group_region_new|" \
        -e "s|$origins_volume_size_pattern|$origins_volume_size_new|" \
        -e "s|$origins_instance_type_pattern|$origins_instance_type_new|" \
        -e "s|$origins_min_pattern|$origins_min_new|" \
        -e "s|$origins_max_pattern|$origins_max_new|" \
        -e "s|$edges_volume_size_pattern|$edges_volume_size_new|" \
        -e "s|$edges_instance_type_pattern|$edges_instance_type_new|" \
        -e "s|$edges_min_pattern|$edges_min_new|" \
        -e "s|$edges_max_pattern|$edges_max_new|" \
        -e "s|$transcoders_volume_size_pattern|$transcoders_volume_size_new|" \
        -e "s|$transcoders_instance_type_pattern|$transcoders_instance_type_new|" \
        -e "s|$transcoders_min_pattern|$transcoders_min_new|" \
        -e "s|$transcoders_max_pattern|$transcoders_max_new|" \
        -e "s|$relays_volume_size_pattern|$relays_volume_size_new|" \
        -e "s|$relays_instance_type_pattern|$relays_instance_type_new|" \
        -e "s|$relays_min_pattern|$relays_min_new|" \
        -e "s|$relays_max_pattern|$relays_max_new|" \
        "$nodegroup_config_json" >"$nodegroup_config_json_mod"
}

prepare_node_config_json() {
    log_i "Preparing Node config JSON template for node group: $NODE_GROUP_TYPE"
    
    # Node config - Round Trip Auth
    if [ "$NODE_ROUND_TRIP_AUTH_ENABLE" == "true" ]; then
        log_i "Node Round Trip Auth is enabled"
        local node_rta_host_pattern='NODE_ROUND_TRIP_AUTH_HOST'
        local node_rta_host_new="${NODE_ROUND_TRIP_AUTH_HOST}"

        local node_rta_port_pattern='NODE_ROUND_TRIP_AUTH_PORT'
        local node_rta_port_new="${NODE_ROUND_TRIP_AUTH_PORT}"

        local node_rta_protocol_pattern='NODE_ROUND_TRIP_AUTH_PROTOCOL'
        local node_rta_protocol_new="${NODE_ROUND_TRIP_AUTH_PROTOCOL}"

        local node_rta_endpoint_validate_pattern='NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE'
        local node_rta_endpoint_validate_new="${NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE}"

        local node_rta_endpoint_invalidate_pattern='NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE'
        local node_rta_endpoint_invalidate_new="${NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE}"

        sed -e "s|$node_rta_host_pattern|$node_rta_host_new|" \
            -e "s|$node_rta_port_pattern|$node_rta_port_new|" \
            -e "s|$node_rta_protocol_pattern|$node_rta_protocol_new|" \
            -e "s|$node_rta_endpoint_validate_pattern|$node_rta_endpoint_validate_new|" \
            -e "s|$node_rta_endpoint_invalidate_pattern|$node_rta_endpoint_invalidate_new|" \
            "$node_config_rta_json" >"$node_config_rta_json_mod"
    else
        log_i "Node Round Trip Auth is disabled"
        echo "[]" >"$node_config_rta_json_mod"
    fi

    # Node config - Webhook    
    if [ "$NODE_WEBHOOK_ENABLE" == "true" ]; then
        log_i "Node Webhook is enabled"

        local node_webhook_pattern='NODE_WEBHOOK_ENDPOINT'
        local node_webhook_new="${NODE_WEBHOOK_ENDPOINT}"

        sed -e "s|$node_webhook_pattern|$node_webhook_new|" "$node_config_webhook_json" >"$node_config_webhook_json_mod"

    else
        log_i "Node Webhook is disabled"
        echo "[]" >"$node_config_webhook_json_mod"
    fi

    # Node config - Social Pusher
    if [ "$NODE_SOCIAL_PUSHER_ENABLE" == "true" ]; then
        log_i "Node Social Pusher is enabled"
        cp "$node_config_social_pusher_json" "$node_config_social_pusher_json_mod"
    else
        log_i "Node Social Pusher is disabled"
        echo "[]" >"$node_config_social_pusher_json_mod"
    fi

    # Node config - Restreamer
    if [ "$NODE_RESTREAMER_ENABLE" == "true" ]; then
        log_i "Node Restreamer is enabled"
        local node_restreamer_tsingest_pattern='NODE_RESTREAMER_TSINGEST'
        local node_restreamer_tsingest_new="${NODE_RESTREAMER_TSINGEST}"

        local node_restreamer_ipcam_pattern='NODE_RESTREAMER_IPCAM'
        local node_restreamer_ipcam_new="${NODE_RESTREAMER_IPCAM}"

        local node_restreamer_whip_pattern='NODE_RESTREAMER_WHIP'
        local node_restreamer_whip_new="${NODE_RESTREAMER_WHIP}"

        local node_restreamer_srtingest_pattern='NODE_RESTREAMER_SRTINGEST'
        local node_restreamer_srtingest_new="${NODE_RESTREAMER_SRTINGEST}"

        sed -e "s|$node_restreamer_tsingest_pattern|$node_restreamer_tsingest_new|" \
            -e "s|$node_restreamer_ipcam_pattern|$node_restreamer_ipcam_new|" \
            -e "s|$node_restreamer_whip_pattern|$node_restreamer_whip_new|" \
            -e "s|$node_restreamer_srtingest_pattern|$node_restreamer_srtingest_new|" \
            "$node_config_restreamer_json" >"$node_config_restreamer_json_mod"
    else
        log_i "Node Restreamer is disabled"
        echo "[]" >"$node_config_restreamer_json_mod"
    fi

    # Create empty node config JSONs
    echo "[]" >"$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_origin.json"
    echo "[]" >"$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_edge.json"
    echo "[]" >"$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_transcoder.json"
    echo "[]" >"$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_relay.json"

    # Generate node config JSONs
    generate_node_config_json "$NODE_ROUNT_TRIP_AUTH_TARGET_NODES" "$node_config_rta_json_mod"
    generate_node_config_json "$NODE_WEBHOOK_TARGET_NODES" "$node_config_webhook_json_mod"
    generate_node_config_json "$NODE_SOCIAL_PUSHER_TARGET_NODES" "$node_config_social_pusher_json_mod"
    generate_node_config_json "$NODE_RESTREAMER_TARGET_NODES" "$node_config_restreamer_json_mod"

    # Read the node config JSONs
    origin_list=$(cat "$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_origin.json")
    edge_list=$(cat "$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_edge.json")
    transcoder_list=$(cat "$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_transcoder.json")
    relay_list=$(cat "$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_relay.json")
    
    # Inject the node config JSON into the nodegroup JSON depending on the node group type
    case $NODE_GROUP_TYPE in
    o)  jq --argjson list1 "$origin_list" '.roles.origin.propertyOverrides = $list1' "$nodegroup_config_json_mod" > "$PATH_TO_JSON_TEMPLATES/property_overrides/temp.json" ;;
    oe) jq --argjson list1 "$origin_list" --argjson list2 "$edge_list" '.roles.origin.propertyOverrides = $list1 | .roles.edge.propertyOverrides = $list2' "$nodegroup_config_json_mod" > "$PATH_TO_JSON_TEMPLATES/property_overrides/temp.json" ;;
    oer) jq --argjson list1 "$origin_list" --argjson list2 "$edge_list" --argjson list3 "$relay_list" '.roles.origin.propertyOverrides = $list1 | .roles.edge.propertyOverrides = $list2 | .roles.relay.propertyOverrides = $list3' "$nodegroup_config_json_mod" > "$PATH_TO_JSON_TEMPLATES/property_overrides/temp.json" ;;
    oet) jq --argjson list1 "$origin_list" --argjson list2 "$edge_list" --argjson list3 "$transcoder_list" '.roles.origin.propertyOverrides = $list1 | .roles.edge.propertyOverrides = $list2 | .roles.transcoder.propertyOverrides = $list3' "$nodegroup_config_json_mod" > "$PATH_TO_JSON_TEMPLATES/property_overrides/temp.json" ;;
    oetr) jq --argjson list1 "$origin_list" --argjson list2 "$edge_list" --argjson list3 "$transcoder_list" --argjson list4 "$relay_list" '.roles.origin.propertyOverrides = $list1 | .roles.edge.propertyOverrides = $list2 | .roles.transcoder.propertyOverrides = $list3 | .roles.relay.propertyOverrides = $list4' "$nodegroup_config_json_mod" > "$PATH_TO_JSON_TEMPLATES/property_overrides/temp.json" ;;
    esac

    # Move the modified nodegroup JSON to the original file
    mv "$PATH_TO_JSON_TEMPLATES/property_overrides/temp.json" "$nodegroup_config_json_mod"

    log_d "JSON template: $nodegroup_config_json_mod"
    cat "$nodegroup_config_json_mod"

    # Delete temporary files
    rm -f "$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_origin.json"
    rm -f "$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_edge.json"
    rm -f "$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_transcoder.json"
    rm -f "$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_relay.json"
}

generate_node_config_json() {
    target_nodes="$1"
    node_config_json="$2"

    IFS=',' read -r -a target_nodes_nodes_array <<< "$target_nodes"

    for i in "${target_nodes_nodes_array[@]}"
    do
        # log_i "TARGET_NODE=$i"
        jq -s '.[0] + .[1]' "$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_$i.json" "$node_config_json" > "$PATH_TO_JSON_TEMPLATES/property_overrides/temp.json"
        mv "$PATH_TO_JSON_TEMPLATES/property_overrides/temp.json" "$PATH_TO_JSON_TEMPLATES/property_overrides/node_config_$i.json"
    done
    rm "$node_config_json"
}

# Check if the minimum number of nodes is set
if [ -z "$ORIGINS_MIN" ]; then
    ORIGINS_MIN=0
fi
if [ -z "$EDGES_MIN" ]; then
    EDGES_MIN=0
fi
if [ -z "$RELAYS_MIN" ]; then
    RELAYS_MIN=0
fi
if [ -z "$TRANSCODERS_MIN" ]; then
    TRANSCODERS_MIN=0
fi

# Check the node group type. Supported types: o, oe, oer, oet, oetr
if [ "$ORIGINS_MIN" -gt 0 ] && [ "$EDGES_MIN" -gt 0 ] && [ "$RELAYS_MIN" -gt 0 ] && [ "$TRANSCODERS_MIN" -gt 0 ]; then
    NODE_GROUP_TYPE="oetr"
elif [ "$ORIGINS_MIN" -gt 0 ] && [ "$EDGES_MIN" -gt 0 ] && [ "$RELAYS_MIN" -gt 0 ]; then
    NODE_GROUP_TYPE="oer"
elif [ "$ORIGINS_MIN" -gt 0 ] && [ "$EDGES_MIN" -gt 0 ] && [ "$TRANSCODERS_MIN" -gt 0 ]; then
    NODE_GROUP_TYPE="oet"
elif [ "$ORIGINS_MIN" -gt 0 ] && [ "$EDGES_MIN" -gt 0 ]; then
    NODE_GROUP_TYPE="oe"
elif [ "$ORIGINS_MIN" -gt 0 ]; then
    NODE_GROUP_TYPE="o"
else
    log_e "Node group type was not found: $NODE_GROUP_TYPE, EXIT..."
    exit 1
fi

log_i "NODE_GROUP_TYPE: $NODE_GROUP_TYPE"

case $NODE_GROUP_TYPE in
o)
    nodegroup_config_name="nodegroup-o"
    nodegroup_config_json="$PATH_TO_JSON_TEMPLATES/nodegroup_config_o.json"
    nodegroup_config_json_mod="$PATH_TO_JSON_TEMPLATES/nodegroup_config_o_mod.json"
    ;;
oe)
    nodegroup_config_name="nodegroup-oe"
    nodegroup_config_json="$PATH_TO_JSON_TEMPLATES/nodegroup_config_oe.json"
    nodegroup_config_json_mod="$PATH_TO_JSON_TEMPLATES/nodegroup_config_oe_mod.json"
    ;;
oer)
    nodegroup_config_name="nodegroup-oer"
    nodegroup_config_json="$PATH_TO_JSON_TEMPLATES/nodegroup_config_oer.json"
    nodegroup_config_json_mod="$PATH_TO_JSON_TEMPLATES/nodegroup_config_oer_mod.json"
    ;;
oet)
    nodegroup_config_name="nodegroup-oet"
    nodegroup_config_json="$PATH_TO_JSON_TEMPLATES/nodegroup_config_oet.json"
    nodegroup_config_json_mod="$PATH_TO_JSON_TEMPLATES/nodegroup_config_oet_mod.json"
    ;;
oetr)
    nodegroup_config_name="nodegroup-oetr"
    nodegroup_config_json="$PATH_TO_JSON_TEMPLATES/nodegroup_config_oetr.json"
    nodegroup_config_json_mod="$PATH_TO_JSON_TEMPLATES/nodegroup_config_oetr_mod.json"
    ;;
*)
    log_e "Node group type was not found: $NODE_GROUP_TYPE, EXIT..."
    exit 1
    ;;
esac

check_stream_manager() {
    SM_STATUS_URL="$SM_URL/as/v1/admin/healthz"

    log_i "Checking Stream Manager status. URL: $SM_STATUS_URL"

    for i in {1..20}; do
        curl --insecure -s -m 5 -o /dev/null -w "%{http_code}" "$SM_STATUS_URL" >/dev/null
        if [ $? -eq 0 ]; then
            code_resp=$(curl --insecure -s -o /dev/null -w "%{http_code}" "$SM_STATUS_URL")
            if [ "$code_resp" -eq 200 ]; then
                log_i "Stream Manager is running. Status code: $code_resp"
                break
            else
                log_i "Stream Manager is not running. Status code: $code_resp"
            fi
        else
            log_w "Stream Manager is not running! - Attempt $i"
        fi

        if [ "$i" -eq 20 ]; then
            log_e "EXIT..."
            exit 1
        fi
        sleep 30
    done
}

create_jwT_token() {
    log_i "Creating JWT token..."
    USER_AND_PASSWORD_IN_BASE64=$(echo -n "$R5AS_AUTH_USER:$R5AS_AUTH_PASS" | base64)

    for i in {1..5}; do
        JVT_TOKEN_JSON=$(curl --insecure -s -X 'PUT' "$SM_URL/as/v1/auth/login" -H 'accept: application/json' -H "Authorization: Basic $USER_AND_PASSWORD_IN_BASE64")
        JVT_TOKEN=$(jq -r '.token' <<<"$JVT_TOKEN_JSON")

        if [ -z "$JVT_TOKEN" ] || [ "$JVT_TOKEN" == "null" ]; then
            log_w "JWT token was not created! - Attempt $i"
            log_d "JVT_TOKEN_JSON: $JVT_TOKEN_JSON"
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

create_new_node_group() {
    log_i "Creating a new Node Group with name: $nodegroup_config_name"

    for i in {1..5}; do
        node_group_resp=$(curl --insecure -s -o /dev/null -w "%{http_code}" --location --request POST "$SM_URL/as/v1/admin/nodegroup" --header "Authorization: Bearer ${JVT_TOKEN}" --header 'Content-Type: application/json' --data "@$nodegroup_config_json_mod")

        if [[ "$node_group_resp" == "200" ]]; then
            log_i "Node group created successfully."
            break
        else
            log_w "Node group was not created! - Attempt $i"
        fi

        if [ "$i" -eq 5 ]; then
            node_group_resp_error=$(curl --insecure -s --request POST "$SM_URL/as/v1/admin/nodegroup" --header "Authorization: Bearer ${JVT_TOKEN}" --header 'Content-Type: application/json' --data "@$nodegroup_config_json_mod")
            log_d "Node group response with error: $node_group_resp_error"
            log_e "Node group was not created!!! EXIT..."
            exit 1
        fi
        sleep 30
    done
}

check_node_group() {
    log_i "Checking states of nodes in new node group, Name: $nodegroup_config_name"

    NODES_URL="$SM_URL/as/v1/admin/nodegroup/status/$nodegroup_config_name"
    
    for i in {1..20}; do
        curl --insecure -s --request GET "$NODES_URL" --header "Authorization: Bearer ${JVT_TOKEN}" | jq -r '.[] | [.scalingEvent.nodeId, .nodeEvent.publicIp // "null", .nodeEvent.privateIp // "null", .nodeEvent.nodeRoleName // "null", .scalingEvent.state, .scalingEvent.test // "null"] | join(" ")' > temp.txt

        node_bad_state=0

        if [ ! -s temp.txt ]; then
            log_d "Nodes are not ready yet! - Attempt $i"
            node_bad_state=1
        else
            while read line; do
                node_id=$(echo "$line" | awk '{print $1}')
                node_public_ip=$(echo "$line" | awk '{print $2}')
                node_private_ip=$(echo "$line" | awk '{print $3}')
                node_role=$(echo "$line" | awk '{print $4}')
                node_state=$(echo "$line" | awk '{print $5}')

                if [[ "$node_state" == "INSERVICE" ]]; then
                    log_i "NodeID: $node_id, NodePublicIP: $node_public_ip, NodePrivateIP: $node_private_ip, NodeRole: $node_role, NodeState: $node_state - READY"
                else
                    log_d "NodeID: $node_id, NodePublicIP: $node_public_ip, NodePrivateIP: $node_private_ip, NodeRole: $node_role, NodeState: $node_state - NOT READY"
                    node_bad_state=1
                fi
            done <temp.txt
        fi

        if [[ $node_bad_state -ne 1 ]]; then
            log_i "All nodes are ready to go! :)"
            if [ -f temp.txt ]; then
                rm temp.txt
            fi
            break
        fi

        if [[ $i -eq 10 ]]; then
            log_e "Something wrong with nodes states. (SM2.0 was not able to create nodes or nodes can't connect to SM). EXIT..."
            exit 1
        fi
        sleep 30
    done
}

prepare_json_templates
prepare_node_config_json
check_stream_manager
create_jwT_token
create_new_node_group
check_node_group

# Delete temporary file
rm -f "$nodegroup_config_json_mod"