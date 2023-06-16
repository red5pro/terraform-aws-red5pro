# AWS Red5 Pro Terraform module

Terraform Red5 Pro AWS module which create Red5 Pro resources on AWS.

## This module has 3 variants of Red5 Pro deployments

* **single** - Single EC2 instance with installed and configured Red5 Pro server
* **cluster** - Stream Manager cluster (MySQL DB + Stream Manager instance + Autoscaling Node group with Origin, Edge, Transcoder, Relay instances)
* **autoscaling** - Autoscaling Stream Managers (MySQL RDS + Load Balancer + Autoscaling Stream Managers + Autoscaling Node group with Origin, Edge, Transcoder, Relay instances)

---

## Preparation

* Download Red5 Pro server build: (Example: red5pro-server-10.9.2.b735-release.zip) https://account.red5pro.com/downloads
* Download Red5 Pro Autoscale controller for AWS: (Example: aws-cloud-controller-10.9.0.jar) https://account.red5pro.com/downloads
* Get Red5 Pro License key: (Example: 1111-2222-3333-4444) https://account.red5pro.com
* Get AWS Access key and AWS Secret key or use existing (AWS IAM - EC2 full access, RDS full access, VPC full access, Certificate manager read only)
* Copy Red5 Pro server build and Red5 Pro Autoscale controller for AWS to folder with installations scripts: `./red5pro-installer/`

Example:  

```bash
cp ~/Downloads/red5pro-server-10.9.2.b735-release.zip ./red5pro-installer/
cp ~/Downloads/aws-cloud-controller-10.9.0.jar ./red5pro-installer/
```

## Single Red5 Pro server deployment (single) - [example](examples/single.tf)

* VPC create or use existing
* Elastic IP create or use existing
* Security group create or use existing
* SSH key create or use existing
* SSL certificate install Let's encrypt or use Red5Pro server without SSL certificate (HTTP only)

## Usage (single)

```hcl
module "red5pro" {
  source = "./modules/red5pro-aws"

  type = "single"                                                            # Deployment type: single, cluster, autoscaling
  name = "red5pro-single"                                                    # Name to be used on all the resources as identifier

  # SSH key configuration
  ssh_key_create            = false                                           # true - create new SSH key, false - use existing SSH key
  ssh_key_name              = "red5pro"                                       # Name for new SSH key or for existing SSH key
  ssh_private_key_path      = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/red5pro.pem" # Path to existing SSH private key
  
  # VPC configuration
  vpc_create      = false                                                      # true - create new VPC, false - use existing VPC
  vpc_id_existing = "vpc-b310bfd7"                                             # VPC ID for existing VPC

  # Security group configuration
  security_group_create      = false                                          # true - create new security group, false - use existing security group
  security_group_id_existing = "sg-0f0b2b6b7f7b1b1a9"                         # Security group ID for existing security group

  # Elastic IP configuration
  elastic_ip_create           = false                                         # true - create new elastic IP, false - use existing elastic IP
  elastic_ip_existing         = "52.53.69.196"                                # Elastic IP for existing elastic IP

  # Single Red5 Pro server HTTPS/SSL certificate configuration
  https_letsencrypt_enable                   = true                           # true - create new Let's Encrypt HTTPS/SSL certificate, false - use Red5 Pro server without HTTPS/SSL certificate
  https_letsencrypt_certificate_domain_name  = "terra-single-server.red5.net" # Domain name for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_email        = "oles@infrared5.com"           # Email for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_password     = "abc123"                       # Password for Let's Encrypt SSL certificate
  
  # Single Red5 Pro server EC2 instance configuration
  single_instance_type = "t2.medium"                                                 # Instance type for Red5 Pro server
  single_volume_size   = 8                                                           # Volume size for Red5 Pro server

  # Red5Pro server configuration
  red5pro_license_key            = "1111-2222-3333-4444"                      # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_api_enable             = true                                       # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://qa-site.red5pro.com/docs/development/api/overview/#gatsby-focus-wrapper)
  red5pro_api_key                = "abc123"                                   # Red5 Pro server API key (https://qa-site.red5pro.com/docs/development/api/overview/#gatsby-focus-wrapper)
  red5pro_inspector_enable       = false                                      # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  red5pro_restreamer_enable      = false                                      # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://qa-site.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  red5pro_socialpusher_enable    = false                                      # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  red5pro_suppressor_enable      = false                                      # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  red5pro_hls_enable             = false                                      # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  red5pro_round_trip_auth_enable = false                                      # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://qa-site.red5pro.com/docs/special/round-trip-auth/overview/)
  
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

---

## Red5 Pro Stream Manager cluster deployment (cluster) - [example](examples/cluster.tf)

* VPC create or use existing
* Elastic IP create or use existing
* Security groups will be created automatically (Stream Manager, Nodes, MySQL DB)
* SSH key create or use existing
* MySQL DB create in RDS or install it locally on the Stream Manager
* Stream Manager instance will be created automatically
* SSL certificate install Let's encrypt or use Red5 Pro Stream Manager without SSL certificate (HTTP only)
* Origin node image create
* Edge node image create or not (it is optional)
* Transcoder node image create or not (it is optional)
* Relay node image create or not (it is optional)
* Autoscaling node group using API to Stream Manager (optional) - (https://qa-site.red5pro.com/docs/special/concepts/nodegroup/)

## Usage (cluster)

```hcl
module "red5pro" {
  source = "./modules/red5pro-aws"

  type = "cluster"                                                            # Deployment type: single, cluster, autoscaling
  name = "red5pro-cluster"                                                    # Name to be used on all the resources as identifier

  # AWS authetification variables it use for Stream Manager autoscaling configuration
  aws_region     = "us-west-1"                                               # AWS region 
  aws_access_key = ""                                                        # AWS IAM Access key
  aws_secret_key = ""                                                        # AWS IAM Secret key

  # SSH key configuration
  ssh_key_create          = false                                             # true - create new SSH key, false - use existing SSH key
  ssh_key_name            = "red5pro"                                         # Name for new SSH key or for existing SSH key
  ssh_private_key_path    = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/red5pro.pem"   # Path to existing SSH private key
  
  # VPC configuration
  vpc_create              = false                                              # true - create new VPC, false - use existing VPC
  vpc_id_existing         = "vpc-b310bfd7"                                    # VPC ID for existing VPC

  # MySQL DB configuration
  mysql_rds_create        = false                                             # true - create new RDS instance, false - install local MySQL server on the Stream Manager EC2 instance
  mysql_rds_instance_type = "db.t2.micro"                                     # Instance type for RDS instance
  mysql_user_name         = "smadmin"                                         # MySQL user name
  mysql_password          = "password"                                        # MySQL password
  mysql_port              = 3306                                              # MySQL port

  # Stream Manager Elastic IP configuration
  elastic_ip_create       = false                                             # true - create new elastic IP, false - use existing elastic IP
  elastic_ip_existing     = "52.53.69.196"                                    # Elastic IP for existing elastic IP

  # Stream Manager HTTPS/SSL certificate configuration
  https_letsencrypt_enable                   = true                           # true - create new Let's Encrypt HTTPS/SSL certificate, false - use Red5 Pro server without HTTPS/SSL certificate
  https_letsencrypt_certificate_domain_name  = "terra-sm-cluster.red5.net"    # Domain name for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_email        = "oles@infrared5.com"           # Email for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_password     = "abc123"                       # Password for Let's Encrypt SSL certificate

  # Stream Manager configuration 
  stream_manager_instance_type  = "t3.medium"                                 # Instance type for Stream Manager
  stream_manager_volume_size    = 20                                          # Volume size for Stream Manager
  stream_manager_api_key        = "abc123"                                    # API key for Stream Manager

  # Red5 Pro general configuration
  red5pro_license_key           = "1111-2222-3333-4444"                       # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_cluster_key           = "abc123"                                    # Red5 Pro cluster key
  red5pro_api_enable            = true                                        # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://qa-site.red5pro.com/docs/development/api/overview/#gatsby-focus-wrapper)
  red5pro_api_key               = "abc123"                                    # Red5 Pro server API key (https://qa-site.red5pro.com/docs/development/api/overview/#gatsby-focus-wrapper)

  # Red5 Pro autoscaling Origin node image configuration
  origin_image_instance_type                      = "t3.medium"               # Instance type for Origin node image
  origin_image_volume_size                        = 8                         # Volume size for Origin node image
  origin_image_red5pro_inspector_enable           = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  origin_image_red5pro_restreamer_enable          = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://qa-site.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  origin_image_red5pro_socialpusher_enable        = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  origin_image_red5pro_suppressor_enable          = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  origin_image_red5pro_hls_enable                 = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  origin_image_red5pro_round_trip_auth_enable     = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://qa-site.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Edge node image configuration - (Optional)
  edge_image_create                               = false                     # true - create new Edge node image, false - not create new Edge node image
  edge_image_instance_type                        = "t3.medium"               # Instance type for Edge node image
  edge_image_volume_size                          = 8                         # Volume size for Edge node image
  edge_image_red5pro_inspector_enable             = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  edge_image_red5pro_restreamer_enable            = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://qa-site.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  edge_image_red5pro_socialpusher_enable          = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  edge_image_red5pro_suppressor_enable            = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  edge_image_red5pro_hls_enable                   = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  edge_image_red5pro_round_trip_auth_enable       = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://qa-site.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Transcoder node image configuration - (Optional)
  transcoder_image_create                         = false                     # true - create new Transcoder node image, false - not create new Edge node image
  transcoder_image_instance_type                  = "t3.medium"               # Instance type for Transcoder node image
  transcoder_image_volume_size                    = 8                         # Volume size for Transcoder node image
  transcoder_image_red5pro_inspector_enable       = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  transcoder_image_red5pro_restreamer_enable      = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://qa-site.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  transcoder_image_red5pro_socialpusher_enable    = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  transcoder_image_red5pro_suppressor_enable      = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  transcoder_image_red5pro_hls_enable             = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  transcoder_image_red5pro_round_trip_auth_enable = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://qa-site.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Relay node image configuration - (Optional)
  relay_image_create                              = false                     # true - create new Relay node image, false - not create new Edge node image
  relay_image_instance_type                       = "t3.medium"               # Instance type for Relay node image
  relay_image_volume_size                         = 8                         # Volume size for Relay node image
  relay_image_red5pro_inspector_enable            = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  relay_image_red5pro_restreamer_enable           = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://qa-site.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  relay_image_red5pro_socialpusher_enable         = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  relay_image_red5pro_suppressor_enable           = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  relay_image_red5pro_hls_enable                  = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  relay_image_red5pro_round_trip_auth_enable      = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://qa-site.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Node group - (Optional)
  node_group_create                               = true                      # true - create new Edge node group, false - not create new Edge node group
  node_group_name                                 = "terraform-node-group"    # Node group name
  # Origin node configuration
  node_group_origins                              = 1                         # Number of Origins
  node_group_origins_instance_type                = "t3.medium"               # Instance type for Origins
  node_group_origins_capacity                     = 30                        # Connections capacity for Origins
  # Edge node configuration
  node_group_edges                                = 1                         # Number of Edges
  node_group_edges_instance_type                  = "t3.medium"               # Instance type for Edges
  node_group_edges_capacity                       = 300                       # Connections capacity for Edges
  # Transcoder node configuration
  node_group_transcoders                          = 0                         # Number of Transcoders
  node_group_transcoders_instance_type            = "t3.medium"               # Instance type for Transcoders
  node_group_transcoders_capacity                 = 30                        # Connections capacity for Transcoders
  # Relay node configuration
  node_group_relays                               = 0                         # Number of Relays
  node_group_relays_instance_type                 = "t3.medium"               # Instance type for Relays
  node_group_relays_capacity                      = 30                        # Connections capacity for Relays
  
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

---

## Red5 Pro Stream Manager cluster with AWS autoscaling Stream Managers (autoscaling) - [example](examples/autoscaling.tf)

* VPC create or use existing
* Security groups will be created automatically (Stream Managers, Nodes, MySQL DB)
* SSH key create or use existing
* MySQL DB will be created automaticaly in RDS
* SSL certificate use existing in AWS Certificate Manager or use Load Balancer without SSL certificate (HTTP only) - it can be useful with Cloudflare
* Load Balancer for Stream Managers will be created automatically
* Autoscaling group for Stream Managers will be created automatically
* Stream Manager image will be created automatically
* Launch configuration for Stream Managers will be created automatically
* Target group for Stream Managers will be created automatically
* Origin node image create or not (it is optional)
* Edge node image create or not (it is optional)
* Transcoder node image create or not (it is optional)
* Relay node image create or not (it is optional)
* Autoscaling node group using API to Stream Manager (optional) - (https://qa-site.red5pro.com/docs/special/concepts/nodegroup/)

## Usage (autoscaling)

```hcl
module "red5pro" {
  source = "./modules/red5pro-aws"

  type = "autoscaling"                                                        # Deployment type: single, cluster, autoscaling
  name = "red5pro-auto"                                                       # Name to be used on all the resources as identifier

  # AWS authetification variables it use for Stream Manager autoscaling configuration
  aws_region     = "us-west-1"                                               # AWS region 
  aws_access_key = ""                                                        # AWS IAM Access key
  aws_secret_key = ""                                                        # AWS IAM Secret key

  # SSH key configuration
  ssh_key_create          = false                                             # true - create new SSH key, false - use existing SSH key
  ssh_key_name            = "red5pro"                                         # Name for new SSH key or for existing SSH key
  ssh_private_key_path    = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/red5pro.pem"   # Path to existing SSH private key
  
  # VPC configuration
  vpc_create              = false                                             # true - create new VPC, false - use existing VPC
  vpc_id_existing         = "vpc-b310bfd7"                                    # VPC ID for existing VPC

  # MySQL DB configuration
  mysql_rds_instance_type = "db.t2.micro"                                     # Instance type for RDS instance
  mysql_user_name         = "smadmin"                                         # MySQL user name
  mysql_password          = "password"                                        # MySQL password
  mysql_port              = 3306                                              # MySQL port

  # Load Balancer HTTPS/SSL certificate configuration
  https_certificate_manager_use_existing     = true                           # If you want to use SSL certificate set it to true
  https_certificate_manager_certificate_name = "terra-sm-auto.red5.net"       # Domain name for your SSL certificate

  # Stream Manager configuration 
  stream_manager_instance_type                = "t3.medium"                   # Instance type for Stream Manager
  stream_manager_volume_size                  = 20                            # Volume size for Stream Manager
  stream_manager_api_key                      = "abc123"                      # API key for Stream Manager
  stream_manager_autoscaling_desired_capacity = 1                             # Desired capacity for Stream Manager autoscaling group
  stream_manager_autoscaling_minimum_capacity = 1                             # Minimum capacity for Stream Manager autoscaling group
  stream_manager_autoscaling_maximum_capacity = 1                             # Maximum capacity for Stream Manager autoscaling group

  # Red5 Pro general configuration
  red5pro_license_key           = "1111-2222-3333-4444"                       # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_cluster_key           = "abc123"                                    # Red5 Pro cluster key
  red5pro_api_enable            = true                                        # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://qa-site.red5pro.com/docs/development/api/overview/#gatsby-focus-wrapper)
  red5pro_api_key               = "abc123"                                    # Red5 Pro server API key (https://qa-site.red5pro.com/docs/development/api/overview/#gatsby-focus-wrapper)

  # Red5 Pro autoscaling Origin node image configuration
  origin_image_instance_type                      = "t3.medium"               # Instance type for Origin node image
  origin_image_volume_size                        = 8                         # Volume size for Origin node image
  origin_image_red5pro_inspector_enable           = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  origin_image_red5pro_restreamer_enable          = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://qa-site.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  origin_image_red5pro_socialpusher_enable        = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  origin_image_red5pro_suppressor_enable          = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  origin_image_red5pro_hls_enable                 = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  origin_image_red5pro_round_trip_auth_enable     = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://qa-site.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Edge node image configuration - (Optional)
  edge_image_create                               = false                     # true - create new Edge node image, false - not create new Edge node image
  edge_image_instance_type                        = "t3.medium"               # Instance type for Edge node image
  edge_image_volume_size                          = 8                         # Volume size for Edge node image
  edge_image_red5pro_inspector_enable             = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  edge_image_red5pro_restreamer_enable            = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://qa-site.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  edge_image_red5pro_socialpusher_enable          = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  edge_image_red5pro_suppressor_enable            = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  edge_image_red5pro_hls_enable                   = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  edge_image_red5pro_round_trip_auth_enable       = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://qa-site.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Transcoder node image configuration - (Optional)
  transcoder_image_create                         = false                     # true - create new Transcoder node image, false - not create new Edge node image
  transcoder_image_instance_type                  = "t3.medium"               # Instance type for Transcoder node image
  transcoder_image_volume_size                    = 8                         # Volume size for Transcoder node image
  transcoder_image_red5pro_inspector_enable       = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  transcoder_image_red5pro_restreamer_enable      = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://qa-site.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  transcoder_image_red5pro_socialpusher_enable    = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  transcoder_image_red5pro_suppressor_enable      = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  transcoder_image_red5pro_hls_enable             = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  transcoder_image_red5pro_round_trip_auth_enable = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://qa-site.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Relay node image configuration - (Optional)
  relay_image_create                              = false                     # true - create new Relay node image, false - not create new Edge node image
  relay_image_instance_type                       = "t3.medium"               # Instance type for Relay node image
  relay_image_volume_size                         = 8                         # Volume size for Relay node image
  relay_image_red5pro_inspector_enable            = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  relay_image_red5pro_restreamer_enable           = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://qa-site.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  relay_image_red5pro_socialpusher_enable         = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  relay_image_red5pro_suppressor_enable           = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  relay_image_red5pro_hls_enable                  = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  relay_image_red5pro_round_trip_auth_enable      = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://qa-site.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Node group - (Optional)
  node_group_create                               = true                      # true - create new Edge node group, false - not create new Edge node group
  node_group_name                                 = "terraform-node-group"    # Node group name
  # Origin node configuration
  node_group_origins                              = 1                         # Number of Origins
  node_group_origins_instance_type                = "t3.medium"               # Instance type for Origins
  node_group_origins_capacity                     = 30                        # Connections capacity for Origins
  # Edge node configuration
  node_group_edges                                = 1                         # Number of Edges
  node_group_edges_instance_type                  = "t3.medium"               # Instance type for Edges
  node_group_edges_capacity                       = 300                       # Connections capacity for Edges
  # Transcoder node configuration
  node_group_transcoders                          = 0                         # Number of Transcoders
  node_group_transcoders_instance_type            = "t3.medium"               # Instance type for Transcoders
  node_group_transcoders_capacity                 = 30                        # Connections capacity for Transcoders
  # Relay node configuration
  node_group_relays                               = 0                         # Number of Relays
  node_group_relays_instance_type                 = "t3.medium"               # Instance type for Relays
  node_group_relays_capacity                      = 30                        # Connections capacity for Relays

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

---

**NOTES**

* To activate HTTPS/SSL you need to add DNS A record for Elastic IP (single/cluster) or CNAME record for Load Balancer DNS name (autoscaling)

---

## Future updates

* Add logic to validate existing Security group (open ports)
* Finish configuration scripts for Red5 Pro extra configurations (Round-trip auth, postprocessing, etc.)
* Add logic to create node gorup automaticaly using SM API + scripts - **DONE**
* Add Monitoring tools
* Add Mixer parts

---

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.73 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.73 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ami_from_instance.red5pro_node_edge_image](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ami_from_instance) | resource |
| [aws_ami_from_instance.red5pro_node_origin_image](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ami_from_instance) | resource |
| [aws_ami_from_instance.red5pro_node_relay_image](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ami_from_instance) | resource |
| [aws_ami_from_instance.red5pro_node_transcoder_image](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ami_from_instance) | resource |
| [aws_ami_from_instance.red5pro_sm_image](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ami_from_instance) | resource |
| [aws_autoscaling_attachment.red5pro_sm_aa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment) | resource |
| [aws_autoscaling_group.red5pro_sm_ag](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_db_instance.red5pro_mysql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_parameter_group.red5pro_mysql_pg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_subnet_group.red5pro_mysql_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_eip.elastic_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip_association.elastic_ip_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_instance.red5pro_node_edge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.red5pro_node_origin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.red5pro_node_relay](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.red5pro_node_transcoder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.red5pro_single](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.red5pro_sm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_internet_gateway.red5pro_igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_key_pair.red5pro_ssh_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_launch_template.red5pro_sm_lt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_lb.red5pro_sm_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.red5pro_sm_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.red5pro_sm_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.red5pro_sm_tg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_placement_group.red5pro_sm_pg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/placement_group) | resource |
| [aws_route.red5pro_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table_association.red5pro_subnets_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.red5pro_images_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.red5pro_mysql_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.red5pro_node_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.red5pro_single_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.red5pro_sm_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.red5pro_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.red5pro_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [local_file.red5pro_ssh_key_pem](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.red5pro_ssh_key_pub](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.node_group](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.stop_node_edge](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.stop_node_origin](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.stop_node_relay](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.stop_node_transcoder](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.stop_stream_manager](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [tls_private_key.red5pro_ssh_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_acm_certificate.red5pro_sm_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_ami.latest_ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_eip.elastic_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eip) | data source |
| [aws_key_pair.ssh_key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/key_pair) | data source |
| [aws_subnet.all_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_access_key"></a> [aws\_access\_key](#input\_aws\_access\_key) | AWS access key | `string` | `""` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy the resources | `string` | `""` | no |
| <a name="input_aws_secret_key"></a> [aws\_secret\_key](#input\_aws\_secret\_key) | AWS secret key | `string` | `""` | no |
| <a name="input_edge_image_create"></a> [edge\_image\_create](#input\_edge\_image\_create) | value to set the edge node image | `bool` | `false` | no |
| <a name="input_edge_image_instance_type"></a> [edge\_image\_instance\_type](#input\_edge\_image\_instance\_type) | value to set the instance type for edge node | `string` | `"t2.medium"` | no |
| <a name="input_edge_image_red5pro_hls_enable"></a> [edge\_image\_red5pro\_hls\_enable](#input\_edge\_image\_red5pro\_hls\_enable) | value to set the hls for edge node | `bool` | `false` | no |
| <a name="input_edge_image_red5pro_inspector_enable"></a> [edge\_image\_red5pro\_inspector\_enable](#input\_edge\_image\_red5pro\_inspector\_enable) | value to set the inspector for edge node | `bool` | `false` | no |
| <a name="input_edge_image_red5pro_restreamer_enable"></a> [edge\_image\_red5pro\_restreamer\_enable](#input\_edge\_image\_red5pro\_restreamer\_enable) | value to set the restreamer for edge node | `bool` | `false` | no |
| <a name="input_edge_image_red5pro_round_trip_auth_enable"></a> [edge\_image\_red5pro\_round\_trip\_auth\_enable](#input\_edge\_image\_red5pro\_round\_trip\_auth\_enable) | value to set the round trip auth for edge node | `bool` | `false` | no |
| <a name="input_edge_image_red5pro_round_trip_auth_endpoint_invalidate"></a> [edge\_image\_red5pro\_round\_trip\_auth\_endpoint\_invalidate](#input\_edge\_image\_red5pro\_round\_trip\_auth\_endpoint\_invalidate) | value to set the round trip auth endpoint invalid for edge node | `string` | `"/invalidateCredentials"` | no |
| <a name="input_edge_image_red5pro_round_trip_auth_endpoint_validate"></a> [edge\_image\_red5pro\_round\_trip\_auth\_endpoint\_validate](#input\_edge\_image\_red5pro\_round\_trip\_auth\_endpoint\_validate) | value to set the round trip auth endpoint valid for edge node | `string` | `"/validateCredentials"` | no |
| <a name="input_edge_image_red5pro_round_trip_auth_host"></a> [edge\_image\_red5pro\_round\_trip\_auth\_host](#input\_edge\_image\_red5pro\_round\_trip\_auth\_host) | value to set the round trip auth host for edge node | `string` | `"10.10.10.10"` | no |
| <a name="input_edge_image_red5pro_round_trip_auth_port"></a> [edge\_image\_red5pro\_round\_trip\_auth\_port](#input\_edge\_image\_red5pro\_round\_trip\_auth\_port) | value to set the round trip auth port for edge node | `number` | `3000` | no |
| <a name="input_edge_image_red5pro_round_trip_auth_protocol"></a> [edge\_image\_red5pro\_round\_trip\_auth\_protocol](#input\_edge\_image\_red5pro\_round\_trip\_auth\_protocol) | value to set the round trip auth protocol for edge node | `string` | `"http"` | no |
| <a name="input_edge_image_red5pro_socialpusher_enable"></a> [edge\_image\_red5pro\_socialpusher\_enable](#input\_edge\_image\_red5pro\_socialpusher\_enable) | value to set the socialpusher for edge node | `bool` | `false` | no |
| <a name="input_edge_image_red5pro_suppressor_enable"></a> [edge\_image\_red5pro\_suppressor\_enable](#input\_edge\_image\_red5pro\_suppressor\_enable) | value to set the suppressor for edge node | `bool` | `false` | no |
| <a name="input_edge_image_volume_size"></a> [edge\_image\_volume\_size](#input\_edge\_image\_volume\_size) | value to set the volume size for edge node | `number` | `8` | no |
| <a name="input_elastic_ip_create"></a> [elastic\_ip\_create](#input\_elastic\_ip\_create) | Create a new Elastic IP or use an existing one. true = create new, false = use existing | `bool` | `true` | no |
| <a name="input_elastic_ip_existing"></a> [elastic\_ip\_existing](#input\_elastic\_ip\_existing) | Elastic IP Existing | `string` | `"10.10.10.10"` | no |
| <a name="input_https_certificate_manager_certificate_name"></a> [https\_certificate\_manager\_certificate\_name](#input\_https\_certificate\_manager\_certificate\_name) | AWS Certificate Manager certificate name (autoscaling) | `string` | `""` | no |
| <a name="input_https_certificate_manager_use_existing"></a> [https\_certificate\_manager\_use\_existing](#input\_https\_certificate\_manager\_use\_existing) | Use existing AWS Certificate Manager certificate (autoscaling) | `bool` | `false` | no |
| <a name="input_https_letsencrypt_certificate_domain_name"></a> [https\_letsencrypt\_certificate\_domain\_name](#input\_https\_letsencrypt\_certificate\_domain\_name) | Domain name for Let's Encrypt ssl certificate (single/cluster) | `string` | `""` | no |
| <a name="input_https_letsencrypt_certificate_email"></a> [https\_letsencrypt\_certificate\_email](#input\_https\_letsencrypt\_certificate\_email) | Email for Let's Encrypt ssl certificate (single/cluster) | `string` | `"terraform@infrared5.com"` | no |
| <a name="input_https_letsencrypt_certificate_password"></a> [https\_letsencrypt\_certificate\_password](#input\_https\_letsencrypt\_certificate\_password) | Password for Let's Encrypt ssl certificate (single/cluster) | `string` | `""` | no |
| <a name="input_https_letsencrypt_enable"></a> [https\_letsencrypt\_enable](#input\_https\_letsencrypt\_enable) | Enable HTTPS and get SSL certificate using Let's Encrypt automaticaly (single/cluster) | `bool` | `false` | no |
| <a name="input_mysql_password"></a> [mysql\_password](#input\_mysql\_password) | MySQL password | `string` | `""` | no |
| <a name="input_mysql_port"></a> [mysql\_port](#input\_mysql\_port) | MySQL port | `number` | `3306` | no |
| <a name="input_mysql_rds_create"></a> [mysql\_rds\_create](#input\_mysql\_rds\_create) | Create a new MySQL instance | `bool` | `false` | no |
| <a name="input_mysql_rds_instance_type"></a> [mysql\_rds\_instance\_type](#input\_mysql\_rds\_instance\_type) | MySQL instance type | `string` | `"db.t2.micro"` | no |
| <a name="input_mysql_user_name"></a> [mysql\_user\_name](#input\_mysql\_user\_name) | MySQL user name | `string` | `"smadmin"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to be used on all the resources as identifier | `string` | `""` | no |
| <a name="input_node_group_create"></a> [node\_group\_create](#input\_node\_group\_create) | Create new node group | `bool` | `false` | no |
| <a name="input_node_group_edges"></a> [node\_group\_edges](#input\_node\_group\_edges) | Number of Edges | `number` | `0` | no |
| <a name="input_node_group_edges_capacity"></a> [node\_group\_edges\_capacity](#input\_node\_group\_edges\_capacity) | Connections capacity for Edges | `number` | `300` | no |
| <a name="input_node_group_edges_instance_type"></a> [node\_group\_edges\_instance\_type](#input\_node\_group\_edges\_instance\_type) | Instance type for Edges | `string` | `"t3.medium"` | no |
| <a name="input_node_group_name"></a> [node\_group\_name](#input\_node\_group\_name) | Node group name | `string` | `"terraform-node-group"` | no |
| <a name="input_node_group_origins"></a> [node\_group\_origins](#input\_node\_group\_origins) | Number of Origins | `number` | `0` | no |
| <a name="input_node_group_origins_capacity"></a> [node\_group\_origins\_capacity](#input\_node\_group\_origins\_capacity) | Connections capacity for Origins | `number` | `30` | no |
| <a name="input_node_group_origins_instance_type"></a> [node\_group\_origins\_instance\_type](#input\_node\_group\_origins\_instance\_type) | Instance type for Origins | `string` | `"t3.medium"` | no |
| <a name="input_node_group_relays"></a> [node\_group\_relays](#input\_node\_group\_relays) | Number of Relays | `number` | `0` | no |
| <a name="input_node_group_relays_capacity"></a> [node\_group\_relays\_capacity](#input\_node\_group\_relays\_capacity) | Connections capacity for Relays | `number` | `30` | no |
| <a name="input_node_group_relays_instance_type"></a> [node\_group\_relays\_instance\_type](#input\_node\_group\_relays\_instance\_type) | Instance type for Relays | `string` | `"t3.medium"` | no |
| <a name="input_node_group_transcoders"></a> [node\_group\_transcoders](#input\_node\_group\_transcoders) | Number of Transcoders | `number` | `0` | no |
| <a name="input_node_group_transcoders_capacity"></a> [node\_group\_transcoders\_capacity](#input\_node\_group\_transcoders\_capacity) | Connections capacity for Transcoders | `number` | `30` | no |
| <a name="input_node_group_transcoders_instance_type"></a> [node\_group\_transcoders\_instance\_type](#input\_node\_group\_transcoders\_instance\_type) | Instance type for Transcoders | `string` | `"t3.medium"` | no |
| <a name="input_origin_image_create"></a> [origin\_image\_create](#input\_origin\_image\_create) | value to set the origin node image | `bool` | `false` | no |
| <a name="input_origin_image_instance_type"></a> [origin\_image\_instance\_type](#input\_origin\_image\_instance\_type) | value to set the instance type for origin node | `string` | `"t2.medium"` | no |
| <a name="input_origin_image_red5pro_hls_enable"></a> [origin\_image\_red5pro\_hls\_enable](#input\_origin\_image\_red5pro\_hls\_enable) | value to set the hls for origin node | `bool` | `false` | no |
| <a name="input_origin_image_red5pro_inspector_enable"></a> [origin\_image\_red5pro\_inspector\_enable](#input\_origin\_image\_red5pro\_inspector\_enable) | value to set the inspector for origin node | `bool` | `false` | no |
| <a name="input_origin_image_red5pro_restreamer_enable"></a> [origin\_image\_red5pro\_restreamer\_enable](#input\_origin\_image\_red5pro\_restreamer\_enable) | value to set the restreamer for origin node | `bool` | `false` | no |
| <a name="input_origin_image_red5pro_round_trip_auth_enable"></a> [origin\_image\_red5pro\_round\_trip\_auth\_enable](#input\_origin\_image\_red5pro\_round\_trip\_auth\_enable) | value to set the round trip auth for origin node | `bool` | `false` | no |
| <a name="input_origin_image_red5pro_round_trip_auth_endpoint_invalidate"></a> [origin\_image\_red5pro\_round\_trip\_auth\_endpoint\_invalidate](#input\_origin\_image\_red5pro\_round\_trip\_auth\_endpoint\_invalidate) | value to set the round trip auth endpoint invalid for origin node | `string` | `""` | no |
| <a name="input_origin_image_red5pro_round_trip_auth_endpoint_validate"></a> [origin\_image\_red5pro\_round\_trip\_auth\_endpoint\_validate](#input\_origin\_image\_red5pro\_round\_trip\_auth\_endpoint\_validate) | value to set the round trip auth endpoint valid for origin node | `string` | `""` | no |
| <a name="input_origin_image_red5pro_round_trip_auth_host"></a> [origin\_image\_red5pro\_round\_trip\_auth\_host](#input\_origin\_image\_red5pro\_round\_trip\_auth\_host) | value to set the round trip auth host for origin node | `string` | `""` | no |
| <a name="input_origin_image_red5pro_round_trip_auth_port"></a> [origin\_image\_red5pro\_round\_trip\_auth\_port](#input\_origin\_image\_red5pro\_round\_trip\_auth\_port) | value to set the round trip auth port for origin node | `number` | `0` | no |
| <a name="input_origin_image_red5pro_round_trip_auth_protocol"></a> [origin\_image\_red5pro\_round\_trip\_auth\_protocol](#input\_origin\_image\_red5pro\_round\_trip\_auth\_protocol) | value to set the round trip auth protocol for origin node | `string` | `""` | no |
| <a name="input_origin_image_red5pro_socialpusher_enable"></a> [origin\_image\_red5pro\_socialpusher\_enable](#input\_origin\_image\_red5pro\_socialpusher\_enable) | value to set the socialpusher for origin node | `bool` | `false` | no |
| <a name="input_origin_image_red5pro_suppressor_enable"></a> [origin\_image\_red5pro\_suppressor\_enable](#input\_origin\_image\_red5pro\_suppressor\_enable) | value to set the suppressor for origin node | `bool` | `false` | no |
| <a name="input_origin_image_volume_size"></a> [origin\_image\_volume\_size](#input\_origin\_image\_volume\_size) | value to set the volume size for origin node | `number` | `8` | no |
| <a name="input_red5pro_api_enable"></a> [red5pro\_api\_enable](#input\_red5pro\_api\_enable) | Red5 Pro Single server API enable | `bool` | `true` | no |
| <a name="input_red5pro_api_key"></a> [red5pro\_api\_key](#input\_red5pro\_api\_key) | Red5 Pro Single server API key | `string` | `""` | no |
| <a name="input_red5pro_cluster_key"></a> [red5pro\_cluster\_key](#input\_red5pro\_cluster\_key) | Red5 Pro node cluster key | `string` | `""` | no |
| <a name="input_red5pro_hls_enable"></a> [red5pro\_hls\_enable](#input\_red5pro\_hls\_enable) | Red5 Pro Single server HLS enable | `bool` | `false` | no |
| <a name="input_red5pro_inspector_enable"></a> [red5pro\_inspector\_enable](#input\_red5pro\_inspector\_enable) | Red5 Pro Single server Inspector enable | `bool` | `false` | no |
| <a name="input_red5pro_license_key"></a> [red5pro\_license\_key](#input\_red5pro\_license\_key) | Red5 Pro license key | `string` | `""` | no |
| <a name="input_red5pro_restreamer_enable"></a> [red5pro\_restreamer\_enable](#input\_red5pro\_restreamer\_enable) | Red5 Pro Single server Restreamer enable | `bool` | `false` | no |
| <a name="input_red5pro_round_trip_auth_enable"></a> [red5pro\_round\_trip\_auth\_enable](#input\_red5pro\_round\_trip\_auth\_enable) | value to set the round trip auth for origin node | `bool` | `false` | no |
| <a name="input_red5pro_round_trip_auth_endpoint_invalidate"></a> [red5pro\_round\_trip\_auth\_endpoint\_invalidate](#input\_red5pro\_round\_trip\_auth\_endpoint\_invalidate) | value to set the round trip auth endpoint invalid for origin node | `string` | `""` | no |
| <a name="input_red5pro_round_trip_auth_endpoint_validate"></a> [red5pro\_round\_trip\_auth\_endpoint\_validate](#input\_red5pro\_round\_trip\_auth\_endpoint\_validate) | value to set the round trip auth endpoint valid for origin node | `string` | `""` | no |
| <a name="input_red5pro_round_trip_auth_host"></a> [red5pro\_round\_trip\_auth\_host](#input\_red5pro\_round\_trip\_auth\_host) | value to set the round trip auth host for origin node | `string` | `""` | no |
| <a name="input_red5pro_round_trip_auth_port"></a> [red5pro\_round\_trip\_auth\_port](#input\_red5pro\_round\_trip\_auth\_port) | value to set the round trip auth port for origin node | `number` | `0` | no |
| <a name="input_red5pro_round_trip_auth_protocol"></a> [red5pro\_round\_trip\_auth\_protocol](#input\_red5pro\_round\_trip\_auth\_protocol) | value to set the round trip auth protocol for origin node | `string` | `""` | no |
| <a name="input_red5pro_socialpusher_enable"></a> [red5pro\_socialpusher\_enable](#input\_red5pro\_socialpusher\_enable) | Red5 Pro Single server SocialPusher enable | `bool` | `false` | no |
| <a name="input_red5pro_suppressor_enable"></a> [red5pro\_suppressor\_enable](#input\_red5pro\_suppressor\_enable) | Red5 Pro Single server Suppressor enable | `bool` | `false` | no |
| <a name="input_relay_image_create"></a> [relay\_image\_create](#input\_relay\_image\_create) | Create relay node image - true or false | `bool` | `false` | no |
| <a name="input_relay_image_instance_type"></a> [relay\_image\_instance\_type](#input\_relay\_image\_instance\_type) | value to set the instance type for relay node | `string` | `"t2.medium"` | no |
| <a name="input_relay_image_red5pro_hls_enable"></a> [relay\_image\_red5pro\_hls\_enable](#input\_relay\_image\_red5pro\_hls\_enable) | value to set the hls for relay node | `bool` | `false` | no |
| <a name="input_relay_image_red5pro_inspector_enable"></a> [relay\_image\_red5pro\_inspector\_enable](#input\_relay\_image\_red5pro\_inspector\_enable) | value to set the inspector for relay node | `bool` | `false` | no |
| <a name="input_relay_image_red5pro_restreamer_enable"></a> [relay\_image\_red5pro\_restreamer\_enable](#input\_relay\_image\_red5pro\_restreamer\_enable) | value to set the restreamer for relay node | `bool` | `false` | no |
| <a name="input_relay_image_red5pro_round_trip_auth_enable"></a> [relay\_image\_red5pro\_round\_trip\_auth\_enable](#input\_relay\_image\_red5pro\_round\_trip\_auth\_enable) | value to set the round trip auth for relay node | `bool` | `false` | no |
| <a name="input_relay_image_red5pro_round_trip_auth_endpoint_invalidate"></a> [relay\_image\_red5pro\_round\_trip\_auth\_endpoint\_invalidate](#input\_relay\_image\_red5pro\_round\_trip\_auth\_endpoint\_invalidate) | value to set the round trip auth endpoint invalid for relay node | `string` | `"/invalidateCredentials"` | no |
| <a name="input_relay_image_red5pro_round_trip_auth_endpoint_validate"></a> [relay\_image\_red5pro\_round\_trip\_auth\_endpoint\_validate](#input\_relay\_image\_red5pro\_round\_trip\_auth\_endpoint\_validate) | value to set the round trip auth endpoint valid for relay node | `string` | `"/validateCredentials"` | no |
| <a name="input_relay_image_red5pro_round_trip_auth_host"></a> [relay\_image\_red5pro\_round\_trip\_auth\_host](#input\_relay\_image\_red5pro\_round\_trip\_auth\_host) | value to set the round trip auth host for relay node | `string` | `"10.10.10.10"` | no |
| <a name="input_relay_image_red5pro_round_trip_auth_port"></a> [relay\_image\_red5pro\_round\_trip\_auth\_port](#input\_relay\_image\_red5pro\_round\_trip\_auth\_port) | value to set the round trip auth port for relay node | `number` | `3000` | no |
| <a name="input_relay_image_red5pro_round_trip_auth_protocol"></a> [relay\_image\_red5pro\_round\_trip\_auth\_protocol](#input\_relay\_image\_red5pro\_round\_trip\_auth\_protocol) | value to set the round trip auth protocol for relay node | `string` | `"http"` | no |
| <a name="input_relay_image_red5pro_socialpusher_enable"></a> [relay\_image\_red5pro\_socialpusher\_enable](#input\_relay\_image\_red5pro\_socialpusher\_enable) | value to set the socialpusher for relay node | `bool` | `false` | no |
| <a name="input_relay_image_red5pro_suppressor_enable"></a> [relay\_image\_red5pro\_suppressor\_enable](#input\_relay\_image\_red5pro\_suppressor\_enable) | value to set the suppressor for relay node | `bool` | `false` | no |
| <a name="input_relay_image_volume_size"></a> [relay\_image\_volume\_size](#input\_relay\_image\_volume\_size) | value to set the volume size for relay node | `number` | `8` | no |
| <a name="input_security_group_create"></a> [security\_group\_create](#input\_security\_group\_create) | Create a new Security group or use an existing one. true = create new, false = use existing | `bool` | `false` | no |
| <a name="input_security_group_id_existing"></a> [security\_group\_id\_existing](#input\_security\_group\_id\_existing) | Security group ID, this Security group should have open default Red5Pro ports: TCP:443,5080,80,1935,8554, UDP:40000-65535 | `string` | `"sg-000"` | no |
| <a name="input_security_group_mysql_egress"></a> [security\_group\_mysql\_egress](#input\_security\_group\_mysql\_egress) | Security group for MySQL - egress | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "-1",<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_security_group_mysql_ingress"></a> [security\_group\_mysql\_ingress](#input\_security\_group\_mysql\_ingress) | Security group for MySQL - ingress | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 3306,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "tcp",<br>    "to_port": 3306<br>  }<br>]</pre> | no |
| <a name="input_security_group_node_egress"></a> [security\_group\_node\_egress](#input\_security\_group\_node\_egress) | Security group for Node - egress | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "-1",<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_security_group_node_ingress"></a> [security\_group\_node\_ingress](#input\_security\_group\_node\_ingress) | Security group for Node - ingress | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 22,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "tcp",<br>    "to_port": 22<br>  },<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 5080,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "tcp",<br>    "to_port": 5080<br>  },<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 1935,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "tcp",<br>    "to_port": 1935<br>  },<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 8554,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "tcp",<br>    "to_port": 8554<br>  },<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 8000,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "udp",<br>    "to_port": 8001<br>  },<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 40000,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "udp",<br>    "to_port": 65535<br>  }<br>]</pre> | no |
| <a name="input_security_group_single_egress"></a> [security\_group\_single\_egress](#input\_security\_group\_single\_egress) | Security group for Single Red5Pro server - egress | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "-1",<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_security_group_single_ingress"></a> [security\_group\_single\_ingress](#input\_security\_group\_single\_ingress) | Security group for Single Red5Pro server  - ingress | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 22,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "tcp",<br>    "to_port": 22<br>  },<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 80,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "tcp",<br>    "to_port": 80<br>  },<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 5080,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "tcp",<br>    "to_port": 5080<br>  },<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 1935,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "tcp",<br>    "to_port": 1935<br>  },<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 8554,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "tcp",<br>    "to_port": 8554<br>  },<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 8000,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "udp",<br>    "to_port": 8001<br>  },<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 40000,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "udp",<br>    "to_port": 65535<br>  }<br>]</pre> | no |
| <a name="input_security_group_stream_manager_egress"></a> [security\_group\_stream\_manager\_egress](#input\_security\_group\_stream\_manager\_egress) | Security group for Stream Managers - egress | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "-1",<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_security_group_stream_manager_ingress"></a> [security\_group\_stream\_manager\_ingress](#input\_security\_group\_stream\_manager\_ingress) | Security group for Stream Managers - ingress | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 22,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "tcp",<br>    "to_port": 22<br>  },<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 443,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "tcp",<br>    "to_port": 443<br>  },<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 5080,<br>    "ipv6_cidr_block": "::/0",<br>    "protocol": "tcp",<br>    "to_port": 5080<br>  }<br>]</pre> | no |
| <a name="input_single_instance_type"></a> [single\_instance\_type](#input\_single\_instance\_type) | Red5 Pro Single server instance type | `string` | `"t2.medium"` | no |
| <a name="input_single_volume_size"></a> [single\_volume\_size](#input\_single\_volume\_size) | Red5 Pro Single server volume size | `number` | `8` | no |
| <a name="input_ssh_key_create"></a> [ssh\_key\_create](#input\_ssh\_key\_create) | Create a new SSH key pair or use an existing one. true = create new, false = use existing | `bool` | `true` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | SSH key pair name existing | `string` | `"red5pro_ssh_key"` | no |
| <a name="input_ssh_private_key_path"></a> [ssh\_private\_key\_path](#input\_ssh\_private\_key\_path) | SSH private key path existing | `string` | `"/home/ubuntu/.ssh/red5pro_ssh_key.pem"` | no |
| <a name="input_stream_manager_api_key"></a> [stream\_manager\_api\_key](#input\_stream\_manager\_api\_key) | value to set the api key for stream manager | `string` | `""` | no |
| <a name="input_stream_manager_autoscaling"></a> [stream\_manager\_autoscaling](#input\_stream\_manager\_autoscaling) | value to enable autoscaling for stream manager | `bool` | `false` | no |
| <a name="input_stream_manager_autoscaling_desired_capacity"></a> [stream\_manager\_autoscaling\_desired\_capacity](#input\_stream\_manager\_autoscaling\_desired\_capacity) | value to set the desired capacity for stream manager autoscaling | `number` | `1` | no |
| <a name="input_stream_manager_autoscaling_maximum_capacity"></a> [stream\_manager\_autoscaling\_maximum\_capacity](#input\_stream\_manager\_autoscaling\_maximum\_capacity) | value to set the maximum capacity for stream manager autoscaling | `number` | `1` | no |
| <a name="input_stream_manager_autoscaling_minimum_capacity"></a> [stream\_manager\_autoscaling\_minimum\_capacity](#input\_stream\_manager\_autoscaling\_minimum\_capacity) | value to set the minimum capacity for stream manager autoscaling | `number` | `1` | no |
| <a name="input_stream_manager_create"></a> [stream\_manager\_create](#input\_stream\_manager\_create) | Create a new Stream Manager instance | `bool` | `true` | no |
| <a name="input_stream_manager_instance_type"></a> [stream\_manager\_instance\_type](#input\_stream\_manager\_instance\_type) | value to set the instance type for stream manager | `string` | `"t2.medium"` | no |
| <a name="input_stream_manager_volume_size"></a> [stream\_manager\_volume\_size](#input\_stream\_manager\_volume\_size) | value to set the volume size for stream manager | `number` | `16` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_transcoder_image_create"></a> [transcoder\_image\_create](#input\_transcoder\_image\_create) | Create transcoder node image - true or false | `bool` | `false` | no |
| <a name="input_transcoder_image_instance_type"></a> [transcoder\_image\_instance\_type](#input\_transcoder\_image\_instance\_type) | value to set the instance type for transcoder node | `string` | `"t2.medium"` | no |
| <a name="input_transcoder_image_red5pro_hls_enable"></a> [transcoder\_image\_red5pro\_hls\_enable](#input\_transcoder\_image\_red5pro\_hls\_enable) | value to set the hls for transcoder node | `bool` | `false` | no |
| <a name="input_transcoder_image_red5pro_inspector_enable"></a> [transcoder\_image\_red5pro\_inspector\_enable](#input\_transcoder\_image\_red5pro\_inspector\_enable) | value to set the inspector for transcoder node | `bool` | `false` | no |
| <a name="input_transcoder_image_red5pro_restreamer_enable"></a> [transcoder\_image\_red5pro\_restreamer\_enable](#input\_transcoder\_image\_red5pro\_restreamer\_enable) | value to set the restreamer for transcoder node | `bool` | `false` | no |
| <a name="input_transcoder_image_red5pro_round_trip_auth_enable"></a> [transcoder\_image\_red5pro\_round\_trip\_auth\_enable](#input\_transcoder\_image\_red5pro\_round\_trip\_auth\_enable) | value to set the round trip auth for transcoder node | `bool` | `false` | no |
| <a name="input_transcoder_image_red5pro_round_trip_auth_endpoint_invalidate"></a> [transcoder\_image\_red5pro\_round\_trip\_auth\_endpoint\_invalidate](#input\_transcoder\_image\_red5pro\_round\_trip\_auth\_endpoint\_invalidate) | value to set the round trip auth endpoint invalid for transcoder node | `string` | `"/invalidateCredentials"` | no |
| <a name="input_transcoder_image_red5pro_round_trip_auth_endpoint_validate"></a> [transcoder\_image\_red5pro\_round\_trip\_auth\_endpoint\_validate](#input\_transcoder\_image\_red5pro\_round\_trip\_auth\_endpoint\_validate) | value to set the round trip auth endpoint valid for transcoder node | `string` | `"/validateCredentials"` | no |
| <a name="input_transcoder_image_red5pro_round_trip_auth_host"></a> [transcoder\_image\_red5pro\_round\_trip\_auth\_host](#input\_transcoder\_image\_red5pro\_round\_trip\_auth\_host) | value to set the round trip auth host for transcoder node | `string` | `"10.10.10.10"` | no |
| <a name="input_transcoder_image_red5pro_round_trip_auth_port"></a> [transcoder\_image\_red5pro\_round\_trip\_auth\_port](#input\_transcoder\_image\_red5pro\_round\_trip\_auth\_port) | value to set the round trip auth port for transcoder node | `number` | `3000` | no |
| <a name="input_transcoder_image_red5pro_round_trip_auth_protocol"></a> [transcoder\_image\_red5pro\_round\_trip\_auth\_protocol](#input\_transcoder\_image\_red5pro\_round\_trip\_auth\_protocol) | value to set the round trip auth protocol for transcoder node | `string` | `"http"` | no |
| <a name="input_transcoder_image_red5pro_socialpusher_enable"></a> [transcoder\_image\_red5pro\_socialpusher\_enable](#input\_transcoder\_image\_red5pro\_socialpusher\_enable) | value to set the socialpusher for transcoder node | `bool` | `false` | no |
| <a name="input_transcoder_image_red5pro_suppressor_enable"></a> [transcoder\_image\_red5pro\_suppressor\_enable](#input\_transcoder\_image\_red5pro\_suppressor\_enable) | value to set the suppressor for transcoder node | `bool` | `false` | no |
| <a name="input_transcoder_image_volume_size"></a> [transcoder\_image\_volume\_size](#input\_transcoder\_image\_volume\_size) | value to set the volume size for transcoder node | `number` | `8` | no |
| <a name="input_type"></a> [type](#input\_type) | Type of deployment: single, cluster, autoscaling | `string` | `""` | no |
| <a name="input_vpc_create"></a> [vpc\_create](#input\_vpc\_create) | Create a new VPC or use an existing one. true = create new, false = use existing | `bool` | `true` | no |
| <a name="input_vpc_id_existing"></a> [vpc\_id\_existing](#input\_vpc\_id\_existing) | VPC ID, this VPC should have minimum 2 public subnets. | `string` | `"vpc-000"` | no |
| <a name="input_vpc_public_subnets"></a> [vpc\_public\_subnets](#input\_vpc\_public\_subnets) | A list of public subnets inside the VPC | `list(string)` | <pre>[<br>  "10.5.0.0/22",<br>  "10.5.4.0/22",<br>  "10.5.8.0/22",<br>  "10.5.12.0/22",<br>  "10.5.16.0/22"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_load_balancer_dns_name"></a> [load\_balancer\_dns\_name](#output\_load\_balancer\_dns\_name) | Load Balancer DNS Name |
| <a name="output_load_balancer_http_url"></a> [load\_balancer\_http\_url](#output\_load\_balancer\_http\_url) | Load Balancer HTTP URL |
| <a name="output_load_balancer_https_url"></a> [load\_balancer\_https\_url](#output\_load\_balancer\_https\_url) | Load Balancer HTTPS URL |
| <a name="output_mysql_host"></a> [mysql\_host](#output\_mysql\_host) | MySQL host |
| <a name="output_mysql_local_enable"></a> [mysql\_local\_enable](#output\_mysql\_local\_enable) | Enable local MySQL |
| <a name="output_mysql_rds_create"></a> [mysql\_rds\_create](#output\_mysql\_rds\_create) | Create MySQL RDS instance |
| <a name="output_node_edge_image"></a> [node\_edge\_image](#output\_node\_edge\_image) | AMI image name of the Red5 Pro Node Edge image |
| <a name="output_node_origin_image"></a> [node\_origin\_image](#output\_node\_origin\_image) | AMI image name of the Red5 Pro Node Origin image |
| <a name="output_node_relay_image"></a> [node\_relay\_image](#output\_node\_relay\_image) | AMI image name of the Red5 Pro Node Relay image |
| <a name="output_node_transcoder_image"></a> [node\_transcoder\_image](#output\_node\_transcoder\_image) | AMI image name of the Red5 Pro Node Transcoder image |
| <a name="output_single_red5pro_server_http_url"></a> [single\_red5pro\_server\_http\_url](#output\_single\_red5pro\_server\_http\_url) | Single Red5 Pro Server HTTP URL |
| <a name="output_single_red5pro_server_https_url"></a> [single\_red5pro\_server\_https\_url](#output\_single\_red5pro\_server\_https\_url) | Single Red5 Pro Server HTTPS URL |
| <a name="output_single_red5pro_server_ip"></a> [single\_red5pro\_server\_ip](#output\_single\_red5pro\_server\_ip) | Single Red5 Pro Server IP |
| <a name="output_ssh_key_name"></a> [ssh\_key\_name](#output\_ssh\_key\_name) | SSH key name |
| <a name="output_ssh_private_key_path"></a> [ssh\_private\_key\_path](#output\_ssh\_private\_key\_path) | SSH private key path |
| <a name="output_stream_manager_http_url"></a> [stream\_manager\_http\_url](#output\_stream\_manager\_http\_url) | Stream Manager HTTP URL |
| <a name="output_stream_manager_https_url"></a> [stream\_manager\_https\_url](#output\_stream\_manager\_https\_url) | Stream Manager HTTPS URL |
| <a name="output_stream_manager_ip"></a> [stream\_manager\_ip](#output\_stream\_manager\_ip) | Stream Manager IP |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Subnet IDs |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | VPC Name |
