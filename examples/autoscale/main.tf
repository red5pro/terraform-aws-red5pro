####################################################################################
# Example for Red5 Pro Stream Manager cluster with AWS autoscaling Stream Managers #
####################################################################################

provider "aws" {
  region     = "us-east-1" # AWS region
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
  aws_region     = "us-east-1" # AWS region 
  aws_access_key = ""          # AWS IAM Access key
  aws_secret_key = ""          # AWS IAM Secret key

  # SSH key configuration
  ssh_key_create       = true                                              # true - create new SSH key, false - use existing SSH key
  ssh_key_name         = "example_key.pem"                                 # Name of existing SSH key private key
  ssh_private_key_path = "/PATH/TO/SSH/PUBLIC/KEY/example_private_key.pem" # Path to existing SSH private key

  # VPC configuration
  vpc_use_existing = false       # true - use existing VPC and subnets, false - create new VPC and subnets
  vpc_id_existing  = "vpc-12345" # VPC ID for existing VPC

  # Kafka standalone instance configuration
  kafka_standalone_instance_type = "c5.2xlarge" # Instance type for Kafka standalone instance
  kafka_standalone_volume_size   = 16           # Volume size in GB for Kafka standalone instance

  # Stream Manager configuration 
  stream_manager_instance_type                = "c5.2xlarge"       # Instance type for Stream Manager
  stream_manager_volume_size                  = 16                 # Volume size for Stream Manager
  stream_manager_autoscaling_desired_capacity = 1                  # Desired capacity for Stream Manager autoscaling group
  stream_manager_autoscaling_minimum_capacity = 1                  # Minimum capacity for Stream Manager autoscaling group
  stream_manager_autoscaling_maximum_capacity = 2                  # Maximum capacity for Stream Manager autoscaling group
  stream_manager_auth_user                    = "example_user"     # Stream Manager 2.0 authentication user name
  stream_manager_auth_password                = "example_password" # Stream Manager 2.0 authentication password

  # Stream Manager 2.0 Load Balancer HTTPS (SSL) certificate configuration
  https_ssl_certificate = "none" # none - do not use HTTPS/SSL certificate, imported - import existing HTTPS/SSL certificate

  # Example of imported HTTPS/SSL certificate configuration - please uncomment and provide your domain name, certificate and key paths
  # https_ssl_certificate                = "imported"            # Improt local HTTPS/SSL certificate to AWS ACM
  # https_ssl_certificate_domain_name    = "red5pro.example.com" # Replace with your domain name
  # https_ssl_certificate_cert_path      = "./cert.pem"          # Path to cert file
  # https_ssl_certificate_key_path       = "./privkey.pem"       # Path to privkey file
  # https_ssl_certificate_fullchain_path = "./fullchain.pem"     # Path to full chain file

  # Example of existing HTTPS/SSL certificate configuration - please uncomment and provide your domain name
  # https_ssl_certificate             = "existing"             # Use existing HTTPS/SSL certificate from AWS ACM
  # https_ssl_certificate_domain_name = "red5pro.example.com"  # Replace with your domain name

  # Red5 Pro general configuration
  red5pro_license_key = "1111-2222-3333-4444" # Red5 Pro license key (https://account.red5.net/login)
  red5pro_api_enable  = true                  # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5.net/docs/development/api/overview/)
  red5pro_api_key     = "example_key"         # Red5 Pro server API key (https://www.red5.net/docs/development/api/overview/)

  # Red5 Pro autoscaling Node image configuration
  node_image_create        = true        # Default: true for Autoscaling and Cluster, true - create new Node image, false - not create new Node image
  node_image_instance_type = "t3.medium" # Instance type for Node image

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

  # Red5 Pro autoscaling Node group
  node_group_create                    = true        # Linux or Mac OS only. true - create new Node group, false - not create new Node group
  node_group_origins_min               = 1           # Number of minimum Origins
  node_group_origins_max               = 20          # Number of maximum Origins
  node_group_origins_instance_type     = "t3.medium" # Instance type for Origins
  node_group_origins_volume_size       = 16          # Volume size for Origins
  node_group_edges_min                 = 1           # Number of minimum Edges
  node_group_edges_max                 = 20          # Number of maximum Edges
  node_group_edges_instance_type       = "t3.medium" # Instance type for Edges
  node_group_edges_volume_size         = 16          # Volume size for Edges
  node_group_transcoders_min           = 0           # Number of minimum Transcoders
  node_group_transcoders_max           = 20          # Number of maximum Transcoders
  node_group_transcoders_instance_type = "t3.medium" # Instance type for Transcoders
  node_group_transcoders_volume_size   = 16          # Volume size for Transcoders
  node_group_relays_min                = 0           # Number of minimum Relays
  node_group_relays_max                = 20          # Number of maximum Relays
  node_group_relays_instance_type      = "t3.medium" # Instance type for Relays
  node_group_relays_volume_size        = 16          # Volume size for Relays

  # Red5 Pro tags configuration - it will be added to all Red5 Pro resources
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "red5pro"
  }
}
