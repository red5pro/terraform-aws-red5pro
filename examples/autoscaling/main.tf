####################################################################################
# Example for Red5 Pro Stream Manager cluster with AWS autoscaling Stream Managers #
####################################################################################

provider "aws" {
  region     = "us-west-1" # AWS region
  access_key = ""          # AWS IAM Access key
  secret_key = ""          # AWS IAM Secret key
}

module "red5pro" {
  source                = "../../"
  type                  = "autoscale"                             # Deployment type: standalone, cluster, autoscale
  name                  = "red5pro-auto"                          # Name to be used on all the resources as identifier
  path_to_red5pro_build = "./red5pro-server-0.0.0.b0-release.zip" # Absolute path or relative path to Red5 Pro server ZIP file
  ubuntu_version        = "22.04"                                 # Ubuntu version for Red5 Pro servers

  # AWS authetification variables it use for Stream Manager autoscaling configuration
  aws_region     = "us-west-1" # AWS region 
  aws_access_key = ""          # AWS IAM Access key
  aws_secret_key = ""          # AWS IAM Secret key

  # SSH key configuration
  # ssh_key_use_existing              = false                                              # true - use existing SSH key, false - create new SSH key
  # ssh_key_existing_private_key_path = "/PATH/TO/SSH/PRIVATE/KEY/example_private_key.pem" # Path to existing SSH private key
  # ssh_key_existing_public_key_path  = "/PATH/TO/SSH/PUBLIC/KEY/example_pub_key.pem"      # Path to existing SSH Public key
  ssh_key_create       = true                                                # true - create new SSH key, false - use existing SSH key
  ssh_key_name         = "example_key"                                       # Name for new SSH key or for existing SSH key
  ssh_private_key_path = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/example_key.pem" # Path to existing SSH private key
  aws_ssh_key_pair     = "example_key"                                       # SSH key pair name

  # VPC configuration
  vpc_create      = true        # true - create new VPC, false - use existing VPC
  vpc_id_existing = "vpc-12345" # VPC ID for existing VPC

  # Kafka standalone instance configuration
  kafka_standalone_instance_type = "t3.medium" # OCI Instance type for Kafka standalone instance
  kafka_standalone_volume_size   = 50          # Volume size in GB for Kafka standalone instance


  # Load Balancer HTTPS/SSL certificate configuration
  https_certificate_manager_use_existing     = true                  # If you want to use SSL certificate set it to true
  https_certificate_manager_certificate_name = "red5pro.example.com" # Domain name for your SSL certificate

  # Stream Manager configuration 
  stream_manager_instance_type                = "t3.medium"         # Instance type for Stream Manager
  stream_manager_volume_size                  = 20                  # Volume size for Stream Manager
  stream_manager_api_key                      = "examplekey"        # API key for Stream Manager
  stream_manager_autoscaling_desired_capacity = 1                   # Desired capacity for Stream Manager autoscaling group
  stream_manager_autoscaling_minimum_capacity = 1                   # Minimum capacity for Stream Manager autoscaling group
  stream_manager_autoscaling_maximum_capacity = 1                   # Maximum capacity for Stream Manager autoscaling group
  stream_manager_coturn_enable                = false               # true - enable customized Coturn configuration for Stream Manager, false - disable customized Coturn configuration for Stream Manager (https://www.red5.net/docs/installation/turn-stun/turnstun/)
  stream_manager_coturn_address               = "stun:1.2.3.4:3478" # Customized coturn address for Stream Manager (https://www.red5.net/docs/installation/turn-stun/turnstun/)
  stream_manager_auth_user                    = "example_user"      # Stream Manager 2.0 authentication user name
  stream_manager_auth_password                = "examplepassword"  # Stream Manager 2.0 authentication password

  # Stream Manager 2.0 Load Balancer HTTPS (SSL) certificate configuration
  https_ssl_certificate = "none" # none - do not use HTTPS/SSL certificate, imported - import existing HTTPS/SSL certificate

  # Red5 Pro general configuration
  red5pro_license_key = "1111-2222-3333-4444" # Red5 Pro license key (https://account.red5.net/login)
  red5pro_cluster_key = "example_key"          # Red5 Pro cluster key
  red5pro_api_enable  = true                  # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5.net/docs/development/api/overview/)
  red5pro_api_key     = "examplekey"          # Red5 Pro server API key (https://www.red5.net/docs/development/api/overview/)

  # Red5 Pro autoscaling Origin node image configuration
  node_image_create        = true        # Default: true for Autoscaling and Cluster, true - create new Origin node image, false - not create new Origin node image
  node_image_instance_type = "t3.medium" # Instance type for Origin node image
  node_image_volume_size   = 20          # Volume size for Origin node image
  # Extra configuration for Red5 Pro autoscaling nodes
  # Webhooks configuration - (Optional) https://www.red5.net/docs/special/webhooks/overview/
  node_config_webhooks = {
    enable           = false,
    target_nodes     = ["origin", "edge", "transcoder"],
    webhook_endpoint = "https://test.webhook.app/api/v1/broadcast/webhook"
  }
  # Round trip authentication configuration - (Optional) https://www.red5.net/docs/special/authplugin/simple-auth/
  node_config_round_trip_auth = {
    enable                   = false,
    target_nodes             = ["origin", "edge", "transcoder"],
    auth_host                = "round-trip-auth.example.com",
    auth_port                = 443,
    auth_protocol            = "https://",
    auth_endpoint_validate   = "/validateCredentials",
    auth_endpoint_invalidate = "/invalidateCredentials"
  }
  # Restreamer configuration - (Optional) https://www.red5.net/docs/special/restreamer/overview/
  node_config_restreamer = {
    enable               = false,
    target_nodes         = ["origin", "transcoder"],
    restreamer_tsingest  = true,
    restreamer_ipcam     = true,
    restreamer_whip      = true,
    restreamer_srtingest = true
  }
  # Social Pusher configuration - (Optional) https://www.red5.net/docs/development/social-media-plugin/rest-api/
  node_config_social_pusher = {
    enable       = false,
    target_nodes = ["origin", "edge", "transcoder"],
  }

  # Red5 Pro autoscaling Node group - (Optional)
  node_group_create = true                   # Linux or Mac OS only. true - create new Node group, false - not create new Node group
  node_group_name   = "terraform-node-group" # Node group name
  # Origin node configuration
  node_group_origins_min           = 1           # Number of minimum Origins
  node_group_origins_max           = 20          # Number of maximum Origins
  node_group_origins_instance_type = "t3.medium" # Instance type for Origins
  node_group_origins_capacity      = 20          # Connections capacity for Origins
  # Edge node configuration
  node_group_edges_min           = 1           # Number of minimum Edges
  node_group_edges_max           = 40          # Number of maximum Edges
  node_group_edges_instance_type = "t3.medium" # Instance type for Edges
  node_group_edges_capacity      = 200         # Connections capacity for Edges
  # Transcoder node configuration
  node_group_transcoders_min           = 0           # Number of minimum Transcoders
  node_group_transcoders_max           = 20          # Number of maximum Transcoders
  node_group_transcoders_instance_type = "t3.medium" # Instance type for Transcoders
  node_group_transcoders_capacity      = 20          # Connections capacity for Transcoders
  # Relay node configuration
  node_group_relays_min           = 0           # Number of minimum Relays
  node_group_relays_max           = 20          # Number of maximum Relays
  node_group_relays_instance_type = "t3.medium" # Instance type for Relays
  node_group_relays_capacity      = 20          # Connections capacity for Relays

  # Red5 Pro tags configuration - it will be added to all Red5 Pro resources
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "red5pro"
  }
}

