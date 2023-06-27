#!/bin/bash

# NAME
# SM_IP
# SM_API_KEY
# NODE_GROUP_REGION

# NODE_GROUP_NAME="terra-node-group"

# ORIGINS=1
# EDGES=1
# TRANSCODERS=1
# RELAYS=1

# ORIGIN_INSTANCE_TYPE="c5.large"
# EDGE_INSTANCE_TYPE="c5.large"
# TRANSCODER_INSTANCE_TYPE="c5.large"
# RELAY_INSTANCE_TYPE="c5.large"

# ORIGIN_CAPACITY="30"
# EDGE_CAPACITY="300"
# TRANSCODER_CAPACITY="30"
# RELAY_CAPACITY="30"

# ORIGIN_IMAGE_NAME="origin-image"
# EDGE_IMAGE_NAME="edge-image"
# TRANSCODER_IMAGE_NAME="transcoder-image"
# RELAY_IMAGE_NAME="relay-image"

nodes_name="${NAME}-node"
timestamp=$(date +%s)

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

prepare_json_templates(){
    log_i "Preparing JSON templates"
    log_i "Check available images for Origin, Edge, Transcoder, Relay"

    if [[ -n "$ORIGIN_IMAGE_NAME" || "$ORIGIN_IMAGE_NAME" != "null" ]]; then
        if [[ -z "$EDGE_IMAGE_NAME" || "$EDGE_IMAGE_NAME" == "null" ]]; then
            log_i "Edge image is not set. Using Origin image for Edge"
            EDGE_IMAGE_NAME=$ORIGIN_IMAGE_NAME
        fi
        if [[ -z "$TRANSCODER_IMAGE_NAME" || "$TRANSCODER_IMAGE_NAME" == "null" ]]; then
            log_i "Transcoder image is not set. Using Origin image for Transcoder"
            TRANSCODER_IMAGE_NAME=$ORIGIN_IMAGE_NAME
        fi
        if [[ -z "$RELAY_IMAGE_NAME" || "$RELAY_IMAGE_NAME" == "null" ]]; then
            log_i "Relay image is not set. Using Origin image for Relay"
            RELAY_IMAGE_NAME=$ORIGIN_IMAGE_NAME
        fi
    else
        log_e "Main Origin image is not set. Exit."
    fi

    log_i "-------------------------------------------"
    log_i "Origin image: $ORIGIN_IMAGE_NAME"
    log_i "Edge image: $EDGE_IMAGE_NAME"
    log_i "Transcoder image: $TRANSCODER_IMAGE_NAME"
    log_i "Relay image: $RELAY_IMAGE_NAME"
    log_i "-------------------------------------------"

    launch_config_o='{"launchconfig":{"name":"'${launch_config_name}'","description":"Launch config Origin","image":"'$ORIGIN_IMAGE_NAME'","version":"0.0.3","targets":{"target":[{"role":"origin","instanceType":"'$ORIGIN_INSTANCE_TYPE'","connectionCapacity":"'$ORIGIN_CAPACITY'"}]},"properties":{"property":[{"name":"property-name","value":"property-value"}]},"metadata":{"meta":[{"key":"Name","value":"'${nodes_name}'"}]}}}'
    launch_config_oe='{"launchconfig":{"name":"'${launch_config_name}'","description":"Launch config Origin,Edge","image":"'$ORIGIN_IMAGE_NAME'","version":"0.0.3","targets":{"target":[{"role":"origin","instanceType":"'$ORIGIN_INSTANCE_TYPE'","connectionCapacity":"'$ORIGIN_CAPACITY'"},{"role":"edge","instanceType":"'$EDGE_INSTANCE_TYPE'","connectionCapacity":"'$EDGE_CAPACITY'","image":"'$EDGE_IMAGE_NAME'"}]},"properties":{"property":[{"name":"property-name","value":"property-value"}]},"metadata":{"meta":[{"key":"Name","value":"'${nodes_name}'"}]}}}'
    launch_config_oer='{"launchconfig":{"name":"'${launch_config_name}'","description":"Launch config Origin,Edge,Relay","image":"'$ORIGIN_IMAGE_NAME'","version":"0.0.3","targets":{"target":[{"role":"origin","instanceType":"'$ORIGIN_INSTANCE_TYPE'","connectionCapacity":"'$ORIGIN_CAPACITY'"},{"role":"edge","instanceType":"'$EDGE_INSTANCE_TYPE'","connectionCapacity":"'$EDGE_CAPACITY'","image":"'$EDGE_IMAGE_NAME'"},{"role":"relay","instanceType":"'$RELAY_INSTANCE_TYPE'","connectionCapacity":"'$RELAY_CAPACITY'","image":"'$RELAY_IMAGE_NAME'"}]},"properties":{"property":[{"name":"property-name","value":"property-value"}]},"metadata":{"meta":[{"key":"Name","value":"'${nodes_name}'"}]}}}'
    launch_config_oet='{"launchconfig":{"name":"'${launch_config_name}'","description":"Launch config Origin,Edge,Transcoder","image":"'$ORIGIN_IMAGE_NAME'","version":"0.0.3","targets":{"target":[{"role":"origin","instanceType":"'$ORIGIN_INSTANCE_TYPE'","connectionCapacity":"'$ORIGIN_CAPACITY'"},{"role":"edge","instanceType":"'$EDGE_INSTANCE_TYPE'","connectionCapacity":"'$EDGE_CAPACITY'","image":"'$EDGE_IMAGE_NAME'"},{"role":"transcoder","instanceType":"'$TRANSCODER_INSTANCE_TYPE'","connectionCapacity":"'$TRANSCODER_CAPACITY'","image":"'$TRANSCODER_IMAGE_NAME'"}]},"properties":{"property":[{"name":"property-name","value":"property-value"}]},"metadata":{"meta":[{"key":"Name","value":"'${nodes_name}'"}]}}}'
    launch_config_oetr='{"launchconfig":{"name":"'${launch_config_name}'","description":"Launch config Origin,Edge,Transcoder,Relay","image":"'$ORIGIN_IMAGE_NAME'","version":"0.0.3","targets":{"target":[{"role":"origin","instanceType":"'$ORIGIN_INSTANCE_TYPE'","connectionCapacity":"'$ORIGIN_CAPACITY'"},{"role":"edge","instanceType":"'$EDGE_INSTANCE_TYPE'","connectionCapacity":"'$EDGE_CAPACITY'","image":"'$EDGE_IMAGE_NAME'"},{"role":"relay","instanceType":"'$RELAY_INSTANCE_TYPE'","connectionCapacity":"'$RELAY_CAPACITY'","image":"'$RELAY_IMAGE_NAME'"},{"role":"transcoder","instanceType":"'$TRANSCODER_INSTANCE_TYPE'","connectionCapacity":"'$TRANSCODER_CAPACITY'","image":"'$TRANSCODER_IMAGE_NAME'"}]},"properties":{"property":[{"name":"property-name","value":"property-value"}]},"metadata":{"meta":[{"key":"Name","value":"'${nodes_name}'"}]}}}'

    scale_policy_o='{"policy":{"name":"'${scale_policy_name}'","description":"Terraform Scale policy Origin","type":"com.red5pro.services.autoscaling.model.ScalePolicyMaster","version": "0.0.3","targets":{"region":[{"name":"default","target":[{"role":"origin","maxLimit":40.0,"scaleAdjustment":1.0,"minLimit":'$ORIGINS'.0}]}]}}}'
    scale_policy_oe='{"policy":{"name":"'${scale_policy_name}'","description":"Terraform Scale policy Origin, Edge","type":"com.red5pro.services.autoscaling.model.ScalePolicyMaster","version": "0.0.3","targets":{"region":[{"name":"default","target":[{"role":"edge","maxLimit":80.0,"scaleAdjustment":1.0,"minLimit":'$EDGES'.0},{"role":"origin","maxLimit":40.0,"scaleAdjustment":1.0,"minLimit":'$ORIGINS'.0}]}]}}}'
    scale_policy_oer='{"policy":{"name":"'${scale_policy_name}'","description":"Terraform Scale policy Origin, Edge, Relay","type":"com.red5pro.services.autoscaling.model.ScalePolicyMaster","version": "0.0.3","targets":{"region":[{"name":"default","target":[{"role":"edge","maxLimit":80.0,"scaleAdjustment":1.0,"minLimit":'$EDGES'.0},{"role":"origin","maxLimit":40.0,"scaleAdjustment":1.0,"minLimit":'$ORIGINS'.0},{"role":"relay","maxLimit":40.0,"scaleAdjustment":1.0,"minLimit":'$RELAYS'.0}]}]}}}'
    scale_policy_oet='{"policy":{"name":"'${scale_policy_name}'","description":"Terraform Scale policy Origin, Edge, Transcoder","type":"com.red5pro.services.autoscaling.model.ScalePolicyMaster","version": "0.0.3","targets":{"region":[{"name":"default","target":[{"role":"edge","maxLimit":80.0,"scaleAdjustment":1.0,"minLimit":'$EDGES'.0},{"role":"origin","maxLimit":40.0,"scaleAdjustment":1.0,"minLimit":'$ORIGINS'.0},{"role":"transcoder","maxLimit":40.0,"scaleAdjustment":1.0,"minLimit":'$TRANSCODERS'.0}]}]}}}'
    scale_policy_oetr='{"policy":{"name":"'${scale_policy_name}'","description":"Terraform Scale policy Origin, Edge, Transcoder, Relay","type":"com.red5pro.services.autoscaling.model.ScalePolicyMaster","version": "0.0.3","targets":{"region":[{"name":"default","target":[{"role":"edge","maxLimit":80.0,"scaleAdjustment":1.0,"minLimit":'$EDGES'.0},{"role":"origin","maxLimit":40.0,"scaleAdjustment":1.0,"minLimit":'$ORIGINS'.0},{"role":"transcoder","maxLimit":40.0,"scaleAdjustment":1.0,"minLimit":'$TRANSCODERS'.0},{"role":"relay","maxLimit":40.0,"scaleAdjustment":1.0,"minLimit":'$RELAYS'.0}]}]}}}'
}

check_stream_manager(){
    log_i "Checking Stream Manager status..."
    
    SM_STATUS_URL="http://$SM_IP:5080/streammanager/api/4.0/admin/debug/cloudcontroller?accessToken=$SM_API_KEY"

    for i in {1..20}; do
        curl -s -m 5 -o /dev/null -w "%{http_code}" curl "$SM_STATUS_URL" > /dev/null
        if [ $? -eq 0 ]; then
            code_resp=$(curl -s -o /dev/null -w "%{http_code}" "$SM_STATUS_URL")
            if [ "$code_resp" -eq 200 ]; then
                log_i "Stream Manager is running. Status code: $code_resp"
                break
            else
                log_i "Stream Manager is not running. Status code: $code_resp"
            fi
        else
            log_w "Cycle $i - Stream Manager is not running!"
        fi
        
        if [ "$i" -eq 20 ]; then
            log_e "EXIT..."
        fi
        sleep 5
    done
}

create_scale_policy(){
    log_i "Creating a new Scale Policy with name: $scale_policy_name"
    
    CREATE_SCALE_POLICY_URL="http://$SM_IP:5080/streammanager/api/4.0/admin/configurations/scalepolicy?accessToken=$SM_API_KEY"

    resp=$(curl -s --location --request POST "$CREATE_SCALE_POLICY_URL" --header 'Content-Type: application/json' -d "$scale_policy")
    scale_policy_name_resp=$(echo "$resp" | jq -r '.policy.name')

    if [[ "$scale_policy_name_resp" == "$scale_policy_name" ]]; then
        log_i "Scale policy config created successfully."
    else
        log_w "Response: $resp"
        log_e "Scale policy was not created!!! EXIT..."
    fi
}

create_launch_config(){
    log_i "Creating a new Launch Config with name: $launch_config_name"

    CREATE_LAUNCH_CONFIG_URL="http://$SM_IP:5080/streammanager/api/4.0/admin/configurations/launchconfig?accessToken=$SM_API_KEY"
    
    resp=$(curl -s --location --request POST "$CREATE_LAUNCH_CONFIG_URL" --header 'Content-Type: application/json' -d "$launch_config")
    launch_config_name_resp=$(echo "$resp" | jq -r '.name')

    if [[ "$launch_config_name_resp" == "$launch_config_name" ]]; then
        log_i "Launch config created successfully."
    else
        log_w "Response: $resp"
        log_e "Launch config was not created!!! EXIT..."
    fi
}

create_new_node_group(){
    log_i "Creating a new Node Group with name: $NODE_GROUP_NAME"

    CREATE_NODE_GROUP_URL="http://$SM_IP:5080/streammanager/api/4.0/admin/nodegroup?accessToken=$SM_API_KEY"   
    node_group="{"regions":["$NODE_GROUP_REGION"],"launchConfig":"$launch_config_name","scalePolicy":"$scale_policy_name","name":"$NODE_GROUP_NAME"}"

    resp=$(curl -s --location --request POST "$CREATE_NODE_GROUP_URL" --header 'Content-Type: application/json' -d "$node_group")
    node_group_name_resp=$(echo "$resp" | jq -r '.name')

    if [[ "$node_group_name_resp" == "$NODE_GROUP_NAME" ]]; then
        log_i "Node group created successfully."
    else
        log_w "Response: $resp"
        log_e "Node group was not created!!! EXIT..."
    fi
}

add_origin_to_node_group(){
    log_i "Starting a new Origin ..."

    CREATE_ORIGIN_URL="http://$SM_IP:5080/streammanager/api/4.0/admin/nodegroup/$NODE_GROUP_NAME/node/origin?accessToken=$SM_API_KEY"
    resp=$(curl -s --location --request POST $CREATE_ORIGIN_URL)
    origin_resp=$(echo "$resp" | jq -r '.group')

    if [[ "$origin_resp" == "$NODE_GROUP_NAME" ]]; then
        log_i "Origin started successfully."
    else
        log_w "Response: $resp"
        log_e "Origin was not started!!! EXIT..."
    fi
}

check_node_group(){
    
    log_i "Checking states of nodes in new node group."
    sleep 30
    NODES_URL="http://$SM_IP:5080/streammanager/api/4.0/admin/nodegroup/$NODE_GROUP_NAME/node?accessToken=$SM_API_KEY"
    
    for i in {1..10};
    do
        resp=$(curl -s "$NODES_URL")
        echo "$resp" |jq -r '.[] | [.identifier, .role, .state] | join(" ")' > temp.txt
        
        nodes=$(awk '{print $1}' < temp.txt)
        node_bad_state=0
        
        for index in $nodes
        do
            node_role=$(grep "$index" temp.txt | awk '{print $2}')
            node_state=$(grep "$index" temp.txt | awk '{print $3}')
            if [[ "$node_state" == "inservice" ]]; then
                log_i "Node: $index, role: $node_role, state: $node_state - READY"
            else
                log_w "Node: $index, role: $node_role, state: $node_state - NOT READY"
                node_bad_state=1
            fi
        done
        
        if [[ $node_bad_state -ne 1 ]]; then
            log_i "All nodes are ready to go! :)"
            if [ -f temp.txt ]; then
                rm temp.txt
            fi
            break
        fi
        if [[ $i -eq 10 ]]; then
            log_e "Something wrong with nodes states. (Terraform service can't deploy nodes or nodes can't connect to SM). EXIT..."
        fi
        sleep 30
    done
}

if [ -z "$ORIGINS" ]; then
    ORIGINS=0
fi
if [ -z "$EDGES" ]; then
    EDGES=0
fi
if [ -z "$RELAYS" ]; then
    RELAYS=0
fi
if [ -z "$TRANSCODERS" ]; then
    TRANSCODERS=0
fi

if [ "$ORIGINS" -gt 0 ] && [ "$EDGES" -gt 0 ] && [ "$RELAYS" -gt 0 ] && [ "$TRANSCODERS" -gt 0 ]; then
    NODE_GROUP_TYPE="oetr"
elif [ "$ORIGINS" -gt 0 ] && [ "$EDGES" -gt 0 ] && [ "$RELAYS" -gt 0 ]; then
    NODE_GROUP_TYPE="oer"
elif [ "$ORIGINS" -gt 0 ] && [ "$EDGES" -gt 0 ] && [ "$TRANSCODERS" -gt 0 ]; then
    NODE_GROUP_TYPE="oet"
elif [ "$ORIGINS" -gt 0 ] && [ "$EDGES" -gt 0 ]; then
    NODE_GROUP_TYPE="oe"
elif [ "$ORIGINS" -gt 0 ]; then
    NODE_GROUP_TYPE="o"
else
    log_e "Node group type was not found: $NODE_GROUP_TYPE, EXIT...";
fi

log_i "NODE_GROUP_TYPE: $NODE_GROUP_TYPE"

case $NODE_GROUP_TYPE in
    o) 
        scale_policy_name="${NAME}-scale-policy-${ORIGINS}o-${timestamp}"
        launch_config_name="${NAME}-launch-config-o-${timestamp}"
        prepare_json_templates
        scale_policy=$scale_policy_o
        launch_config=$launch_config_o
    ;;
    oe) 
        scale_policy_name="${NAME}-scale-policy-${ORIGINS}o-${EDGES}e-${timestamp}"
        launch_config_name="${NAME}-launch-config-oe-${timestamp}"
        prepare_json_templates
        scale_policy=$scale_policy_oe
        launch_config=$launch_config_oe
    ;;
    oer) 
        scale_policy_name="${NAME}-scale-policy-${ORIGINS}o-${EDGES}e-${RELAYS}r-${timestamp}"
        launch_config_name="${NAME}-launch-config-oer-${timestamp}"
        prepare_json_templates
        scale_policy=$scale_policy_oer
        launch_config=$launch_config_oer
    ;;
    oet) 
        scale_policy_name="${NAME}-scale-policy-${ORIGINS}o-${EDGES}e-${TRANSCODERS}t-${timestamp}"
        launch_config_name="${NAME}-launch-config-oet-${timestamp}"
        prepare_json_templates
        scale_policy=$scale_policy_oet
        launch_config=$launch_config_oet
    ;;
    oetr) 
        scale_policy_name="${NAME}-scale-policy-${ORIGINS}o-${EDGES}e-${TRANSCODERS}t-${RELAYS}r-${timestamp}"
        launch_config_name="${NAME}-launch-config-oetr-${timestamp}"
        prepare_json_templates
        scale_policy=$scale_policy_oetr
        launch_config=$launch_config_oetr
    ;;
    *) log_e " Node group type was not found: $NODE_GROUP_TYPE, EXIT...";
esac

check_stream_manager
create_scale_policy
create_launch_config
create_new_node_group
add_origin_to_node_group
check_node_group