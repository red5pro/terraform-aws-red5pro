#!/bin/bash
############################################################################################################################################################
# Script Name: r5p_create_node_group.sh
# Description: This script generates node group config json and creates a new Node Group in Stream Manager 2.0 and checks the states of the nodes.
# AUTHOR: Oles Prykhodko
# COMPANY: Infrared5, Inc.
# Date: 2025-04-08
############################################################################################################################################################

# SM_IP="sm-ip-address-example"
# NODE_GROUP_NAME="name-example" # Max 16 characters
# R5AS_AUTH_USER="sm-auth-user-name-example"
# R5AS_AUTH_PASS="sm-auth-password-example"

# NODE_GROUP_CLOUD_PLATFORM="OCI" # AWS, GCP, LINODE, OCI
# NODE_GROUP_REGIONS="us-ashburn-1"
# NODE_GROUP_ENVIRONMENT="environment-name-example"
# NODE_GROUP_SUBNET_NAME="subnet-name-example" #OCI only
# NODE_GROUP_VPC_NAME="vpc-name-example"
# NODE_GROUP_SECURITY_GROUP_NAME="security-group-name-example" # Not used for GCP

# NODE_GROUP_IMAGE_NAME="node-image-name-example"

# NODE_GROUP_ORIGINS_MIN=1
# NODE_GROUP_EDGES_MIN=1
# NODE_GROUP_TRANSCODERS_MIN=0
# NODE_GROUP_RELAYS_MIN=0

# NODE_GROUP_ORIGINS_MAX=20
# NODE_GROUP_EDGES_MAX=40
# NODE_GROUP_TRANSCODERS_MAX=20
# NODE_GROUP_RELAYS_MAX=20

# NODE_GROUP_ORIGIN_INSTANCE_TYPE="e2-medium"
# NODE_GROUP_EDGE_INSTANCE_TYPE="e2-medium"
# NODE_GROUP_TRANSCODER_INSTANCE_TYPE="e2-medium"
# NODE_GROUP_RELAY_INSTANCE_TYPE="e2-medium"

# NODE_GROUP_ORIGIN_VOLUME_SIZE="20"
# NODE_GROUP_EDGE_VOLUME_SIZE="20"
# NODE_GROUP_TRANSCODER_VOLUME_SIZE="20"
# NODE_GROUP_RELAY_VOLUME_SIZE="20"

# NODE_GROUP_ORIGINS_CONNECTION_LIMIT="20"
# NODE_GROUP_EDGES_CONNECTION_LIMIT="200"
# NODE_GROUP_TRANSCODERS_CONNECTION_LIMIT="20"

# NODE_GROUP_ROUND_TRIP_AUTH_ENABLE=true
# NODE_GROUP_ROUNT_TRIP_AUTH_TARGET_NODES="origin,edge,transcoder"
# NODE_GROUP_ROUND_TRIP_AUTH_HOST="rta-host.com.ua"
# NODE_GROUP_ROUND_TRIP_AUTH_PORT="443"
# NODE_GROUP_ROUND_TRIP_AUTH_PROTOCOL="https://"
# NODE_GROUP_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE="/validate"
# NODE_GROUP_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE="/invalidate"

# NODE_GROUP_WEBHOOK_ENABLE=true
# NODE_GROUP_WEBHOOK_TARGET_NODES="origin,edge,transcoder"
# NODE_GROUP_WEBHOOK_ENDPOINT="https://webhook-endpoint.com.ua"

# NODE_GROUP_SOCIAL_PUSHER_ENABLE=true
# NODE_GROUP_SOCIAL_PUSHER_TARGET_NODES="origin,edge,transcoder"

# NODE_GROUP_RESTREAMER_ENABLE=true
# NODE_GROUP_RESTREAMER_TARGET_NODES="origin,edge,transcoder"
# NODE_GROUP_RESTREAMER_TSINGEST=true
# NODE_GROUP_RESTREAMER_IPCAM=true
# NODE_GROUP_RESTREAMER_WHIP=true
# NODE_GROUP_RESTREAMER_SRTINGEST=true

################################################################################################################
NODE_GROUP_ORIGIN_OUT_THRESHOLD="0.6"     # 0.6 = 60%
NODE_GROUP_EDGE_OUT_THRESHOLD="0.6"       # 0.6 = 60%
NODE_GROUP_TRANSCODER_OUT_THRESHOLD="0.6" # 0.6 = 60%

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

if [ "$NODE_GROUP_ORIGINS_MIN" -eq 0 ]; then
    log_e "At least one Origin node is required. Exiting."
    exit 1
fi

# Generate Node group description
NODE_GROUP_DESCRIPTION="Stream Manager 2.0 Node group"

if [ "$NODE_GROUP_ORIGINS_MIN" -gt 0 ]; then
    NODE_GROUP_DESCRIPTION="${NODE_GROUP_DESCRIPTION} with Origin"
fi
if [ "$NODE_GROUP_EDGES_MIN" -gt 0 ]; then
    NODE_GROUP_DESCRIPTION="${NODE_GROUP_DESCRIPTION}, Edge"
fi
if [ "$NODE_GROUP_TRANSCODERS_MIN" -gt 0 ]; then
    NODE_GROUP_DESCRIPTION="${NODE_GROUP_DESCRIPTION}, Transcoder"
fi
if [ "$NODE_GROUP_RELAYS_MIN" -gt 0 ]; then
    NODE_GROUP_DESCRIPTION="${NODE_GROUP_DESCRIPTION}, Relay"
fi

NODE_GROUP_DESCRIPTION="${NODE_GROUP_DESCRIPTION} in ${NODE_GROUP_CLOUD_PLATFORM} cloud platform"

# Generate Cloud properties based on the cloud platform
CLOUD_PROPERTIES_OCI="environment=$NODE_GROUP_ENVIRONMENT;subnet=$NODE_GROUP_SUBNET_NAME;security_group=$NODE_GROUP_SECURITY_GROUP_NAME"
CLOUD_PROPERTIES_AWS="environment=$NODE_GROUP_ENVIRONMENT;vpc=$NODE_GROUP_VPC_NAME;security_group=$NODE_GROUP_SECURITY_GROUP_NAME"
CLOUD_PROPERTIES_GCP="environment=$NODE_GROUP_ENVIRONMENT;vpc=$NODE_GROUP_VPC_NAME"
CLOUD_PROPERTIES_LINODE="environment=$NODE_GROUP_ENVIRONMENT;vpc=$NODE_GROUP_VPC_NAME;security_group=$NODE_GROUP_SECURITY_GROUP_NAME"

# Select cloud properties based on the cloud platform
case $NODE_GROUP_CLOUD_PLATFORM in
"OCI")
    CLOUD_PROPERTIES=$CLOUD_PROPERTIES_OCI
    ;;
"AWS")
    CLOUD_PROPERTIES=$CLOUD_PROPERTIES_AWS
    ;;
"GCP")
    CLOUD_PROPERTIES=$CLOUD_PROPERTIES_GCP
    ;;
"LINODE")
    CLOUD_PROPERTIES=$CLOUD_PROPERTIES_LINODE
    ;;
*)
    log_e "Unknown cloud platform: $NODE_GROUP_CLOUD_PLATFORM. Exiting."
    exit 1
    ;;
esac

# JSON for top level
node_group_json_top_level=$(
    cat <<EOF
{
    "name": "$NODE_GROUP_NAME",
    "description": "$NODE_GROUP_DESCRIPTION",
    "cloudProperties": "$CLOUD_PROPERTIES",
    "cloudPlatform": "$NODE_GROUP_CLOUD_PLATFORM",
    "isScalingPaused": false,
    "internalVersionCount": 0,
    "images": {},
    "roles": {},
    "groups": {}
}
EOF
)

# JSON for Origin image
node_group_json_images_origin=$(
    cat <<EOF
{
    "origin_image": {
        "name": "origin_image",
        "image": "$NODE_GROUP_IMAGE_NAME",
        "cloudProperties": "instance_type=$NODE_GROUP_ORIGIN_INSTANCE_TYPE;volume_size=$NODE_GROUP_ORIGIN_VOLUME_SIZE"
    }
}
EOF
)
# JSON for Edge image
node_group_json_images_edge=$(
    cat <<EOF
{
    "edge_image": {
        "name": "edge_image",
        "image": "$NODE_GROUP_IMAGE_NAME",
        "cloudProperties": "instance_type=$NODE_GROUP_EDGE_INSTANCE_TYPE;volume_size=$NODE_GROUP_EDGE_VOLUME_SIZE"
    }
}
EOF
)
# JSON for Transcoder image
node_group_json_images_transcoder=$(
    cat <<EOF
{
    "transcoder_image": {
        "name": "transcoder_image",
        "image": "$NODE_GROUP_IMAGE_NAME",
        "cloudProperties": "instance_type=$NODE_GROUP_TRANSCODER_INSTANCE_TYPE;volume_size=$NODE_GROUP_TRANSCODER_VOLUME_SIZE"
    }
}
EOF
)
# JSON for Relay image
node_group_json_images_relay=$(
    cat <<EOF
{
    "relay_image": {
        "name": "relay_image",
        "image": "$NODE_GROUP_IMAGE_NAME",
        "cloudProperties": "instance_type=$NODE_GROUP_RELAY_INSTANCE_TYPE;volume_size=$NODE_GROUP_RELAY_VOLUME_SIZE"
    }
}
EOF
)

# Merge JSON for images with top level JSON
if [ "$NODE_GROUP_ORIGINS_MIN" -gt 0 ]; then
    combined_json=$(jq --argjson origin "$(echo "$node_group_json_images_origin" | jq .)" '.images = .images + $origin' <<<"$node_group_json_top_level")
fi
if [ "$NODE_GROUP_EDGES_MIN" -gt 0 ]; then
    combined_json=$(jq --argjson edge "$(echo "$node_group_json_images_edge" | jq .)" '.images = .images + $edge' <<<"$combined_json")
fi
if [ "$NODE_GROUP_TRANSCODERS_MIN" -gt 0 ]; then
    combined_json=$(jq --argjson transcoder "$(echo "$node_group_json_images_transcoder" | jq .)" '.images = .images + $transcoder' <<<"$combined_json")
fi
if [ "$NODE_GROUP_RELAYS_MIN" -gt 0 ]; then
    combined_json=$(jq --argjson relay "$(echo "$node_group_json_images_relay" | jq .)" '.images = .images + $relay' <<<"$combined_json")
fi

# JSON for Origin (all in one) role
node_group_json_roles_origin_allinone=$(
    cat <<EOF
{
    "origin": {
        "name": "origin",
        "imageName": "origin_image",
        "capabilities": ["PUBLISH", "SUBSCRIBE", "TRANSCODE"],
        "propertyOverrides": []
    }
}
EOF
)
# JSON for Origin role
node_group_json_roles_origin=$(
    cat <<EOF
{
    "origin": {
        "name": "origin",
        "imageName": "origin_image",
        "capabilities": ["PUBLISH"],
        "propertyOverrides": []
    }
}
EOF
)
# JSON for Edge role with parent Origin
node_group_json_roles_edge_parent_origin=$(
    cat <<EOF
{
    "edge": {
        "name": "edge",
        "imageName": "edge_image",
        "parentRoleName": "origin",
		"parentCardinality": "GLOBAL",
        "capabilities": ["SUBSCRIBE"],
        "propertyOverrides": []
    }
}
EOF
)
# JSON for Edge role with parent Relay
node_group_json_roles_edge_parent_relay=$(
    cat <<EOF
{
    "edge": {
        "name": "edge",
        "imageName": "edge_image",
        "parentRoleName": "relay",
		"parentCardinality": "AUTOGROUP",
        "capabilities": ["SUBSCRIBE"],
        "propertyOverrides": []
    }
}
EOF
)

# JSON for Transcoder role
node_group_json_roles_transcoder=$(
    cat <<EOF
{
    "transcoder": {
        "name": "transcoder",
        "imageName": "transcoder_image",
        "capabilities": ["TRANSCODE"],
        "propertyOverrides": []
    }
}
EOF
)
# JSON for Relay role
node_group_json_roles_relay=$(
    cat <<EOF
{
    "relay": {
        "name": "relay",
        "imageName": "relay_image",
        "parentRoleName": "origin",
        "parentCardinality": "GLOBAL",
        "capabilities": [],
        "propertyOverrides": []
    }
}
EOF
)

# Merge JSON for roles with top level JSON
if [ "$NODE_GROUP_ORIGINS_MIN" -gt 0 ] && [ "$NODE_GROUP_EDGES_MIN" -eq 0 ] && [ "$NODE_GROUP_TRANSCODERS_MIN" -eq 0 ] && [ "$NODE_GROUP_RELAYS_MIN" -eq 0 ]; then
    combined_json=$(jq --argjson origin "$(echo "$node_group_json_roles_origin_allinone" | jq .)" '.roles = .roles + $origin' <<<"$combined_json")
elif [ "$NODE_GROUP_ORIGINS_MIN" -gt 0 ]; then
    combined_json=$(jq --argjson origin "$(echo "$node_group_json_roles_origin" | jq .)" '.roles = .roles + $origin' <<<"$combined_json")
fi
if [ "$NODE_GROUP_EDGES_MIN" -gt 0 ]; then
    if [ "$NODE_GROUP_RELAYS_MIN" -gt 0 ]; then
        combined_json=$(jq --argjson edge "$(echo "$node_group_json_roles_edge_parent_relay" | jq .)" '.roles = .roles + $edge' <<<"$combined_json")
    else
        combined_json=$(jq --argjson edge "$(echo "$node_group_json_roles_edge_parent_origin" | jq .)" '.roles = .roles + $edge' <<<"$combined_json")
    fi
fi
if [ "$NODE_GROUP_TRANSCODERS_MIN" -gt 0 ]; then
    combined_json=$(jq --argjson transcoder "$(echo "$node_group_json_roles_transcoder" | jq .)" '.roles = .roles + $transcoder' <<<"$combined_json")
fi
if [ "$NODE_GROUP_RELAYS_MIN" -gt 0 ]; then
    combined_json=$(jq --argjson relay "$(echo "$node_group_json_roles_relay" | jq .)" '.roles = .roles + $relay' <<<"$combined_json")
fi

# Generate JSON for groups for each region
IFS=',' read -r -a regions <<<"$NODE_GROUP_REGIONS"

for region in "${regions[@]}"; do
    log_i "Generating JSON for region: $region"

    # JSON for subgroups - top level
    node_group_json_subgroup_top_level=$(
        cat <<EOF
{
    "$region": {
        "nodeGroupName": "$NODE_GROUP_NAME",
        "subGroupName": "$region",
        "groupType": "main",
        "cloudProperties": "region=$region",
        "rulesByRole": {}
    }
}
EOF
    )
    # JSON for subgroups - Origin
    origin_out_limit=$(echo "$NODE_GROUP_ORIGINS_CONNECTION_LIMIT * $NODE_GROUP_ORIGIN_OUT_THRESHOLD" | bc | awk '{printf "%.0f", $0}')
    node_group_json_subgroup_origin=$(
        cat <<EOF
{
    "origin": {
        "nodeGroupName": "$NODE_GROUP_NAME",
        "subGroupName": "$region",
        "nodeRoleName": "origin",
        "min": "$NODE_GROUP_ORIGINS_MIN",
        "max": "$NODE_GROUP_ORIGINS_MAX",
        "increment": 1,
        "outExpression": "avg(connections.publisher) > $origin_out_limit",
        "inExpression": "avg(connections.publisher) < 2",
        "capacityRankingExpression": "connections.publisher",
        "capacityLimitExpression": "$NODE_GROUP_ORIGINS_CONNECTION_LIMIT"
    }
}
EOF
    )
    # JSON for subgroups - Edge
    edge_out_limit=$(echo "$NODE_GROUP_EDGES_CONNECTION_LIMIT * $NODE_GROUP_EDGE_OUT_THRESHOLD" | bc | awk '{printf "%.0f", $0}')
    node_group_json_subgroup_edge=$(
        cat <<EOF
{
    "edge": {
        "nodeGroupName": "$NODE_GROUP_NAME",
        "subGroupName": "$region",
        "nodeRoleName": "edge",
        "min": "$NODE_GROUP_EDGES_MIN",
        "max": "$NODE_GROUP_EDGES_MAX",
        "increment": 1,
        "outExpression": "avg(connections.subscriber) > $edge_out_limit",
        "inExpression": "avg(connections.subscriber) < 20",
        "capacityRankingExpression": "connections.subscriber",
        "capacityLimitExpression": "$NODE_GROUP_EDGES_CONNECTION_LIMIT"
    }
}
EOF
    )
    # JSON for subgroups - Transcoder
    transcoder_out_limit=$(echo "$NODE_GROUP_TRANSCODERS_CONNECTION_LIMIT * $NODE_GROUP_TRANSCODER_OUT_THRESHOLD" | bc | awk '{printf "%.0f", $0}')
    node_group_json_subgroup_transcoder=$(
        cat <<EOF
{
    "transcoder": {
        "nodeGroupName": "$NODE_GROUP_NAME",
        "subGroupName": "$region",
        "nodeRoleName": "transcoder",
        "min": "$NODE_GROUP_TRANSCODERS_MIN",
        "max": "$NODE_GROUP_TRANSCODERS_MAX",
        "increment": 1,
        "outExpression": "avg(connections.publisher) > $transcoder_out_limit",
        "inExpression": "avg(connections.publisher) < 2",
        "capacityRankingExpression": "connections.publisher",
        "capacityLimitExpression": "$NODE_GROUP_TRANSCODERS_CONNECTION_LIMIT"
    }
}
EOF
    )
    # JSON for subgroups - Relay
    node_group_json_subgroup_relay=$(
        cat <<EOF
{
    "relay": {
        "nodeGroupName": "$NODE_GROUP_NAME",
        "subGroupName": "$region",
        "nodeRoleName": "relay",
        "min": "$NODE_GROUP_RELAYS_MIN",
        "max": "$NODE_GROUP_RELAYS_MAX",
        "increment": 1,
        "outExpression": "avg(connections.clusterchildren) > 8",
        "inExpression": "avg(connections.clusterchildren) < 2",
        "capacityRankingExpression": "0",
        "capacityLimitExpression": "0"
    }
}
EOF
    )
    # Merge JSON for subgroups
    if [ "$NODE_GROUP_ORIGINS_MIN" -gt 0 ]; then
        group_combined_json=$(echo "$node_group_json_subgroup_top_level" | jq --argjson origin "$(echo "$node_group_json_subgroup_origin" | jq .)" '.[].rulesByRole = $origin')
    fi
    if [ "$NODE_GROUP_EDGES_MIN" -gt 0 ]; then
        group_combined_json=$(echo "$group_combined_json" | jq --argjson edge "$(echo "$node_group_json_subgroup_edge" | jq .)" '.[].rulesByRole = .[].rulesByRole + $edge')
    fi
    if [ "$NODE_GROUP_TRANSCODERS_MIN" -gt 0 ]; then
        group_combined_json=$(echo "$group_combined_json" | jq --argjson transcoder "$(echo "$node_group_json_subgroup_transcoder" | jq .)" '.[].rulesByRole = .[].rulesByRole + $transcoder')
    fi
    if [ "$NODE_GROUP_RELAYS_MIN" -gt 0 ]; then
        group_combined_json=$(echo "$group_combined_json" | jq --argjson relay "$(echo "$node_group_json_subgroup_relay" | jq .)" '.[].rulesByRole = .[].rulesByRole + $relay')
    fi

    # Merge JSON for subgroups with top level JSON
    combined_json=$(jq --argjson group "$(echo "$group_combined_json" | jq .)" '.groups = .groups + $group' <<<"$combined_json")

done

############################################################################################################
# Property overrides - extra configurations for each role
############################################################################################################

# Round Trip Auth
node_group_json_property_round_trip_auth=$(
    cat <<EOF
{
    "fileName": "webapps/live/WEB-INF/red5-web.properties",
    "properties": {
        "server.validateCredentialsEndPoint": "$NODE_GROUP_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE",
        "server.invalidateCredentialsEndPoint": "$NODE_GROUP_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE",
        "server.host": "$NODE_GROUP_ROUND_TRIP_AUTH_HOST",
        "server.port": "$NODE_GROUP_ROUND_TRIP_AUTH_PORT",
        "server.protocol": "$NODE_GROUP_ROUND_TRIP_AUTH_PROTOCOL"
    }
}
EOF
)
# Webhooks
node_group_json_property_webhooks=$(
    cat <<EOF
{
    "fileName": "webapps/live/WEB-INF/red5-web.properties",
    "properties": {
        "webhooks.endpoint": "$NODE_GROUP_WEBHOOK_ENDPOINT"
    }
}
EOF
)
# Social Pusher
node_group_json_property_social_pusher=$(
    cat <<EOF
{
    "fileName": "webapps/root/WEB-INF/web.xml",
    "blocks": ["R5AS-SOCIAL-PUSHER"]
}
EOF
)
# Restreamer
node_group_json_property_restreamer=$(
    cat <<EOF
{
    "fileName": "conf/restreamer-plugin.properties",
    "properties": {
        "enable.tsingest": "$NODE_GROUP_RESTREAMER_TSINGEST",
        "enable.ipcam": "$NODE_GROUP_RESTREAMER_IPCAM",
        "enable.whip": "$NODE_GROUP_RESTREAMER_WHIP",
        "enable.srtingest": "$NODE_GROUP_RESTREAMER_SRTINGEST"
    }
}
EOF
)

# Generate property overrides for each node type
generate_json_property_for_nodes() {
    target_nodes="$1"
    node_config_json="$2"

    IFS=',' read -r -a target_nodes_nodes_array <<<"$target_nodes"

    for i in "${target_nodes_nodes_array[@]}"; do
        # Combine the property property overrides (JSON objects) for each node type
        case $i in
        origin)
            node_group_json_property_origin=$(jq --argjson property "$node_config_json" '. + [$property]' <<<"$node_group_json_property_origin")
            ;;
        edge)
            node_group_json_property_edge=$(jq --argjson property "$node_config_json" '. + [$property]' <<<"$node_group_json_property_edge")
            ;;
        transcoder)
            node_group_json_property_transcoder=$(jq --argjson property "$node_config_json" '. + [$property]' <<<"$node_group_json_property_transcoder")
            ;;
        relay)
            node_group_json_property_relay=$(jq --argjson property "$node_config_json" '. + [$property]' <<<"$node_group_json_property_relay")
            ;;
        esac
    done
}

node_group_json_property_origin="[]"
node_group_json_property_edge="[]"
node_group_json_property_transcoder="[]"
node_group_json_property_relay="[]"

# Generate property overrides for each node type. List of JSON objects
if [ "$NODE_GROUP_ROUND_TRIP_AUTH_ENABLE" = true ]; then
    log_i "Round Trip Auth enabled"
    generate_json_property_for_nodes "$NODE_GROUP_ROUNT_TRIP_AUTH_TARGET_NODES" "$node_group_json_property_round_trip_auth"
fi
if [ "$NODE_GROUP_WEBHOOK_ENABLE" = true ]; then
    log_i "Webhooks enabled"
    generate_json_property_for_nodes "$NODE_GROUP_WEBHOOK_TARGET_NODES" "$node_group_json_property_webhooks"
fi
if [ "$NODE_GROUP_SOCIAL_PUSHER_ENABLE" = true ]; then
    log_i "Social Pusher enabled"
    generate_json_property_for_nodes "$NODE_GROUP_SOCIAL_PUSHER_TARGET_NODES" "$node_group_json_property_social_pusher"
fi
if [ "$NODE_GROUP_RESTREAMER_ENABLE" = true ]; then
    log_i "Restreamer enabled"
    generate_json_property_for_nodes "$NODE_GROUP_RESTREAMER_TARGET_NODES" "$node_group_json_property_restreamer"
fi

# Merge property overrides with top level JSON
if [ "$NODE_GROUP_ORIGINS_MIN" -gt 0 ]; then
    combined_json=$(echo "$combined_json" | jq --argjson origin "$(echo "$node_group_json_property_origin" | jq .)" '.roles.origin.propertyOverrides = $origin')
fi
if [ "$NODE_GROUP_EDGES_MIN" -gt 0 ]; then
    combined_json=$(echo "$combined_json" | jq --argjson edge "$(echo "$node_group_json_property_edge" | jq .)" '.roles.edge.propertyOverrides = $edge')
fi
if [ "$NODE_GROUP_TRANSCODERS_MIN" -gt 0 ]; then
    combined_json=$(echo "$combined_json" | jq --argjson transcoder "$(echo "$node_group_json_property_transcoder" | jq .)" '.roles.transcoder.propertyOverrides = $transcoder')
fi
if [ "$NODE_GROUP_RELAYS_MIN" -gt 0 ]; then
    combined_json=$(echo "$combined_json" | jq --argjson relay "$(echo "$node_group_json_property_relay" | jq .)" '.roles.relay.propertyOverrides = $relay')
fi

log_d "Generated JSON:"
echo "$combined_json" | jq -r

############################################################################################################
# Create Node Group in Stream Manager 2.0 (API calls)
############################################################################################################

check_stream_manager() {
    log_i "Checking Stream Manager status."
    log_i "Stream Manager HTTPS: https://$SM_IP/as/v1/admin/healthz or HTTP: http://$SM_IP/as/v1/admin/healthz"

    for i in {1..20}; do
        # Check HTTPS
        https_response=$(curl -s -m 5 -o /dev/null -w "%{http_code}" --insecure "https://$SM_IP/as/v1/admin/healthz")
        if [ "$https_response" -eq 200 ]; then
            SM_URL="https://$SM_IP"
            log_i "SM URL is accessible over HTTPS: $SM_URL"
            break
        fi

        # Check HTTP
        http_response=$(curl -s -m 5 -o /dev/null -w "%{http_code}" "http://$SM_IP/as/v1/admin/healthz")
        if [ "$http_response" -eq 200 ]; then
            SM_URL="http://$SM_IP"
            log_i "SM URL is accessible over HTTP: $SM_URL"
            break
        fi

        log_w "Stream Manager is not running! - Attempt $i"

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
    log_i "Creating a new Node Group with name: $NODE_GROUP_NAME"

    for i in {1..5}; do
        node_group_resp=$(curl --insecure -s -o /dev/null -w "%{http_code}" --location --request POST "$SM_URL/as/v1/admin/nodegroup" --header "Authorization: Bearer ${JVT_TOKEN}" --header 'Content-Type: application/json' --data-raw "$combined_json")

        if [[ "$node_group_resp" == "200" ]]; then
            log_i "Node group created successfully."
            break
        else
            log_w "Node group was not created! - Attempt $i"
        fi

        if [ "$i" -eq 5 ]; then
            node_group_resp_error=$(curl --insecure -s --request POST "$SM_URL/as/v1/admin/nodegroup" --header "Authorization: Bearer ${JVT_TOKEN}" --header 'Content-Type: application/json' --data-raw "$combined_json")
            log_d "Node group response with error: $node_group_resp_error"
            log_e "Node group was not created!!! EXIT..."
            exit 1
        fi
        sleep 30
    done
}

check_node_group() {
    log_i "Checking states of nodes in new node group, Name: $NODE_GROUP_NAME"

    NODES_URL="$SM_URL/as/v1/admin/nodegroup/status/$NODE_GROUP_NAME"

    for i in {1..20}; do
        curl --insecure -s --request GET "$NODES_URL" --header "Authorization: Bearer ${JVT_TOKEN}" | jq -r '.[] | [.scalingEvent.nodeId, .nodeEvent.publicIp // "null", .nodeEvent.privateIp // "null", .nodeEvent.nodeRoleName // "null", .scalingEvent.state, .scalingEvent.test // "null"] | join(" ")' >temp.txt

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

        if [[ $i -eq 20 ]]; then
            log_e "Something wrong with nodes states. (Stream Manager 2.0 was not able to create nodes or nodes can't connect to Stream Manager 2.0)."
            log_e "Please check the nodes in Stream Manager 2.0 and delete/create node group config manually."
            log_e "Stream Manager 2.0 URL: $SM_URL/debug"
            log_e "Documentation: https://www.red5.net/docs/red5-pro/users-guide/stream-manager-2-0/stream-manager-2-node-group-config/"
        fi
        sleep 20
    done
}

check_stream_manager
create_jwT_token
create_new_node_group
check_node_group