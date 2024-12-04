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
  - `imported`: Load Balancer with HTTPS using an imported SSL certificate (HTTP on port `80`, HTTPS on port `443`)
- Red5 Pro (SM2.0) Node instance image (origins, edges, transcoders, relays)
- Red5 Pro (SM2.0) Autoscaling Node group (origins, edges, transcoders, relays)

## Example main.tf (autoscale)

```yaml
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

module "red5pro" {
  source                = "../../"
  type                  = "autoscale"                             # Deployment type: standalone, cluster, autoscale
  name                  = "red5pro-auto"                          # Name to be used on all the resources as identifier
  path_to_red5pro_build = "./red5pro-server-0.0.0.b0-release.zip" # Absolute path or relative path to Red5 Pro server ZIP file

  # SSH Key Configuration
  ssh_key_use_existing              = false                                              # true - use existing SSH key, false - create new SSH key
  ssh_key_existing_private_key_path = "/PATH/TO/SSH/PRIVATE/KEY/example_private_key.pem" # Path to existing SSH private key
  ssh_key_existing_public_key_path  = "/PATH/TO/SSH/PUBLIC/KEY/example_pub_key.pem"      # Path to existing SSH Public key
  aws_ssh_key_pair                  =   "red5pro_ssh_key"          # SSH key pair name
  # Red5 Pro General Configuration
  red5pro_license_key = "1111-2222-3333-4444" # Red5 Pro license key
  red5pro_api_enable  = true                  # true - enable Red5 Pro server API, false - disable Red5 Pro server API
  red5pro_api_key     = "example_key"         # Red5 Pro server API key

  # Stream Manager 2.0 Instance Configuration
  stream_manager_instance_type                = "t3.medium"   # AWS Instance type for Stream Manager
  stream_manager_instance_volume_size         = 50            # Volume size in GB for Stream Manager
  stream_manager_autoscaling_desired_capacity = 1             # Desired capacity for Stream Manager autoscaling group
  stream_manager_autoscaling_minimum_capacity = 1             # Minimum capacity for Stream Manager autoscaling group
  stream_manager_autoscaling_maximum_capacity = 2             # Maximum capacity for Stream Manager autoscaling group
  stream_manager_auth_user                    = "example_user" # Stream Manager 2.0 authentication user name
  stream_manager_auth_password                = "example_password" # Stream Manager 2.0 authentication password

  # Kafka Standalone Instance Configuration
  kafka_standalone_instance_create      = true                  # true - create new Kafka standalone instance, false - do not create
  kafka_standalone_instance_type        = "t3.medium"           # AWS Instance type for Kafka standalone instance
  kafka_standalone_instance_volume_size = 50                    # Volume size in GB for Kafka standalone instance

  # Load Balancer Configuration
  load_balancer_reserved_ip_use_existing = false     # true - use existing reserved IP for Load Balancer, false - create new reserved IP
  load_balancer_reserved_ip_existing     = "1.2.3.4" # Reserved IP for Load Balancer

  # Stream Manager 2.0 Load Balancer HTTPS (SSL) Certificate Configuration
  https_ssl_certificate = "none" # none - do not use HTTPS/SSL certificate, imported - import existing HTTPS/SSL certificate

  # Example of Imported HTTPS/SSL Certificate Configuration
  # https_ssl_certificate             = "imported"
  # https_ssl_certificate_domain_name = "red5pro.example.com"
  # https_ssl_certificate_cert_path   = "/PATH/TO/SSL/CERT/fullchain.pem"
  # https_ssl_certificate_key_path    = "/PATH/TO/SSL/KEY/privkey.pem"

  # Red5 Pro Autoscaling Node Image Configuration
  node_image_create          = true                  # true - create new Red5 Pro Node image
  node_image_instance_type   = "t3.medium"           # AWS Instance type for Red5 Pro Node image
  node_image_instance_volume = 50                    # Volume size in GB for Red5 Pro Node image

  # Extra Configuration for Red5 Pro Autoscaling Nodes
  node_config_webhooks = {
    enable           = false,
    target_nodes     = ["origin", "edge", "transcoder"],   # Nodes that Webhooks target
    webhook_endpoint = "https://test.webhook.app/api/v1/broadcast/webhook"
  }

  node_config_round_trip_auth = {
    enable                   = false,
    target_nodes             = ["origin", "edge", "transcoder"], # Nodes using round trip authentication
    auth_host                = "round-trip-auth.example.com",
    auth_port                = 443,
    auth_protocol            = "https://",
    auth_endpoint_validate   = "/validateCredentials",
    auth_endpoint_invalidate = "/invalidateCredentials"
  }

  node_config_restreamer = {
    enable               = false,
    target_nodes         = ["origin", "transcoder"], # Nodes supporting restreaming
    restreamer_tsingest  = true,
    restreamer_ipcam     = true,
    restreamer_whip      = true,
    restreamer_srtingest = true
  }

  node_config_social_pusher = {
    enable       = false,
    target_nodes = ["origin", "edge", "transcoder"], # Nodes using Social Pusher
  }

  # Red5 Pro Autoscaling Node Group Configuration
  node_group_create                    = true                      # true - create new Node group
  node_group_origins_min               = 1                         # Minimum Origins
  node_group_origins_max               = 20                        # Maximum Origins
  node_group_origins_instance_type     = "t3.medium"               # AWS Instance type for Origins
  node_group_origins_volume_size       = 50                        # Volume size in GB for Origins
  node_group_edges_min                 = 1                         # Minimum Edges
  node_group_edges_max                 = 40                        # Maximum Edges
  node_group_edges_instance_type       = "t3.medium"               # AWS Instance type for Edges
  node_group_edges_volume_size         = 50                        # Volume size in GB for Edges
  node_group_transcoders_min           = 0                         # Minimum Transcoders
  node_group_transcoders_max           = 20                        # Maximum Transcoders
  node_group_transcoders_instance_type = "t3.medium"               # AWS Instance type for Transcoders
  node_group_transcoders_volume_size   = 50                        # Volume size in GB for Transcoders
  node_group_relays_min                = 0                         # Minimum Relays
  node_group_relays_max                = 20                        # Maximum Relays
  node_group_relays_instance_type      = "t3.medium"               # AWS Instance type for Relays
  node_group_relays_volume_size        = 50                        # Volume size in GB for Relays
}

output "module_output" {
  value = module.red5pro
}
```
