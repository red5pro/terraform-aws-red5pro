# Autoscaling Stream Managers 2.0 with Autoscaling Nodes (autoscale) - [Example](https://github.com/red5pro/terraform-aws-red5pro/tree/master/examples/autoscale)

This example Terraform module automates the infrastructure provisioning of Autoscale Stream Managers 2.0 with Red5 Pro (SM2.0) Autoscaling node groups (origins, edges, transcoders, relays) in AWS.

## Terraform Deployed Resources (autoscale)

- VPC
- Public Subnet
- Internet Gateway
- Route Table
- Security Groups:
  - Stream Manager 2.0
  - Kafka
  - Red5 Pro (SM2.0) Autoscaling Nodes
- SSH key pair (use existing or create a new one)
- Standalone Kafka instance
- Stream Manager 2.0 instance image
- Instance pool for Stream Manager 2.0 instances
- Autoscaling configuration for Stream Manager 2.0 instances
- Application Load Balancer for Stream Manager 2.0 instances
- SSL Certificate for Application Load Balancer:
  - `none`: Load Balancer without HTTPS and SSL certificate (HTTP on port `80`)
  - `letsencrypt` - Stream Manager 2.0 with HTTPS and SSL certificate obtained by Let's Encrypt. HTTP on port `80`, HTTPS on port `443`
  - `imported`: Load Balancer with HTTPS using an imported SSL certificate (HTTP on port `80`, HTTPS on port `443`)
- Red5 Pro (SM2.0) Node instance image (origins, edges, transcoders, relays)
- Red5 Pro (SM2.0) Autoscaling Node group (origins, edges, transcoders, relays)

> Note: For cluster deployments, this module also deploys an AWS IAM Role and IAM Policy that are attached to the Stream Manager EC2 instance via an instance profile. This enables the Stream Manager to authenticate to AWS (without static keys) and run Terraform operations as needed.

## Example main.tf (autoscale)

```yaml
provider "aws" {
  region = "us-east-1" # AWS region
}

module "red5pro" {
  source                = "../../"
  type                  = "cluster"                               # Deployment type: standalone, cluster, autoscale
  name                  = "red5pro-cluster"                       # Name to be used on all the resources as identifier
  path_to_red5pro_build = "./red5pro-server-0.0.0.b0-release.zip" # Absolute path or relative path to Red5 Pro server ZIP file
  ubuntu_version        = "22.04"                                 # Ubuntu version for Red5 Pro servers

  # AWS authetification variables it use for Stream Manager autoscaling configuration
  aws_region = "us-east-1" # AWS region 

  # SSH key configuration
  ssh_key_use_existing              = false                                               # Use existing SSH key pair or create a new one. true = use existing, false = create new SSH key pair
  ssh_key_name_existing             = "example_key"                                       # SSH key name existing in AWS
  ssh_key_private_key_path_existing = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/example_key.pem" # SSH private key path existing in local machine

  # VPC configuration
  vpc_use_existing = false       # true - use existing VPC and subnets, false - create new VPC and subnets automatically
  vpc_id_existing  = "vpc-12345" # VPC ID for existing VPC

  # Kafka standalone instance configuration
  kafka_standalone_instance_create = false
  kafka_standalone_instance_type   = "m5.xlarge" # Instance type for Kafka standalone instance
  kafka_standalone_volume_size     = 16          # Volume size in GB for Kafka standalone instance

  # Stream Manager configuration 
  stream_manager_instance_type    = "m5.xlarge"                # Instance type for Stream Manager
  stream_manager_volume_size      = 16                         # Volume size for Stream Manager
  stream_manager_auth_user        = "example_user"             # Stream Manager 2.0 authentication user name
  stream_manager_auth_password    = "example_password"         # Stream Manager 2.0 authentication password
  stream_manager_proxy_user       = "example_proxy_user"       # Stream Manager 2.0 proxy user name
  stream_manager_proxy_password   = "example_proxy_password"   # Stream Manager 2.0 proxy password
  stream_manager_spatial_user     = "example_spatial_user"     # Stream Manager 2.0 spatial user name
  stream_manager_spatial_password = "example_spatial_password" # Stream Manager 2.0 spatial password
  stream_manager_version          = "latest"                   # Stream Manager 2.0 docker images version (latest, 14.1.0, 14.1.1, etc.) - https://hub.docker.com/r/red5pro/as-admin/tags

  # Stream Manager Elastic IP configuration
  stream_manager_elastic_ip_use_existing = false     # true - use existing elastic IP, false - create new elastic IP automatically
  stream_manager_elastic_ip_existing     = "1.2.3.4" # Existing Elastic IP

  # Stream Manager 2.0 server HTTPS (SSL) certificate configuration
  https_ssl_certificate = "none" # none - do not use HTTPS/SSL certificate, letsencrypt - create new Let's Encrypt HTTPS/SSL certificate, imported - use existing HTTPS/SSL certificate

  # Example of Let's Encrypt HTTPS/SSL certificate configuration - please uncomment and provide your domain name and email
  # https_ssl_certificate             = "letsencrypt"
  # https_ssl_certificate_domain_name = "red5pro.example.com" # Replace with your domain name
  # https_ssl_certificate_email       = "email@example.com"   # Replace with your email

  # Example of imported HTTPS/SSL certificate configuration - please uncomment and provide your domain name, certificate and key paths
  # https_ssl_certificate             = "imported"
  # https_ssl_certificate_domain_name = "red5pro.example.com"             # Replace with your domain name
  # https_ssl_certificate_cert_path   = "/PATH/TO/SSL/CERT/fullchain.pem" # Path to cert file or full chain file
  # https_ssl_certificate_key_path    = "/PATH/TO/SSL/KEY/privkey.pem"    # Path to privkey file

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
  node_group_create                       = true        # Linux or Mac OS only. true - create new Node group, false - not create new Node group
  node_group_origins_min                  = 1           # Number of minimum Origins
  node_group_origins_max                  = 20          # Number of maximum Origins
  node_group_origins_instance_type        = "t3.medium" # Instance type for Origins
  node_group_origins_volume_size          = 16          # Volume size for Origins
  node_group_origins_connection_limit     = 20          # Maximum number of publishers to the origin server
  node_group_edges_min                    = 1           # Number of minimum Edges
  node_group_edges_max                    = 20          # Number of maximum Edges
  node_group_edges_instance_type          = "t3.medium" # Instance type for Edges
  node_group_edges_volume_size            = 16          # Volume size for Edges
  node_group_edges_connection_limit       = 200         # Maximum number of subscribers to the edge server
  node_group_transcoders_min              = 0           # Number of minimum Transcoders
  node_group_transcoders_max              = 20          # Number of maximum Transcoders
  node_group_transcoders_instance_type    = "t3.medium" # Instance type for Transcoders
  node_group_transcoders_volume_size      = 16          # Volume size for Transcoders
  node_group_transcoders_connection_limit = 20          # Maximum number of publishers to the transcoder server
  node_group_relays_min                   = 0           # Number of minimum Relays
  node_group_relays_max                   = 20          # Number of maximum Relays
  node_group_relays_instance_type         = "t3.medium" # Instance type for Relays
  node_group_relays_volume_size           = 16          # Volume size for Relays

  # Red5 Pro tags configuration - it will be added to all Red5 Pro resources
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "red5pro"
  }
}

output "module_output" {
  value = module.red5pro
}
```
