# AWS Red5 Pro Terraform module

Terraform Red5 Pro AWS module which create Red5 Pro resources on AWS.

## This module has 3 variants of Red5 Pro deployments

* **single** - Single EC2 instance with installed and configured Red5 Pro server
* **cluster** - Stream Manager cluster (MySQL DB + Stream Manager instance + Autoscaling Node group with Origin, Edge, Transcoder, Relay instances)
* **autoscaling** - Autoscaling Stream Managers (MySQL RDS + Load Balancer + Autoscaling Stream Managers + Autoscaling Node group with Origin, Edge, Transcoder, Relay instances)

---

## Preparation

* Install **terraform** https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
* Install **AWS CLI** https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
* Install **jq** Linux or Mac OS only - `apt install jq` or `brew install jq` (It is using in bash scripts to create/delete Stream Manager node group using API)
* Download Red5 Pro server build: (Example: red5pro-server-11.0.0.b835-release.zip) https://account.red5pro.com/downloads
* Download Red5 Pro Autoscale controller for AWS: (Example: aws-cloud-controller-11.1.0.jar) https://account.red5pro.com/downloads
* Get Red5 Pro License key: (Example: 1111-2222-3333-4444) https://account.red5pro.com
* Get AWS Access key and AWS Secret key or use existing (AWS IAM - EC2 full access, RDS full access, VPC full access, Certificate manager read only)
* Copy Red5 Pro server build and Red5 Pro Autoscale controller for AWS to the root folder of your project

Example:  

```bash
cp ~/Downloads/red5pro-server-11.0.0.b835-release.zip ./
cp ~/Downloads/aws-cloud-controller-11.1.0.jar ./
```

## Single Red5 Pro server deployment (single) - [Example](https://github.com/red5pro/terraform-aws-red5pro/tree/master/examples/single)

* VPC create or use existing
* Elastic IP create or use existing
* Security group create or use existing
* SSH key create or use existing
* SSL certificate install Let's encrypt or use Red5Pro server without SSL certificate (HTTP only)

## Usage (single)

```hcl
module "red5pro" {
  source  = "red5pro/red5pro/aws"

  type = "single"                                                            # Deployment type: single, cluster, autoscaling
  name = "red5pro-single"                                                    # Name to be used on all the resources as identifier

  path_to_red5pro_build        = "./red5pro-server-11.0.0.b835-release.zip"   # Absolute path or relative path to Red5 Pro server ZIP file

  # SSH key configuration
  ssh_key_create            = false                                           # true - create new SSH key, false - use existing SSH key
  ssh_key_name              = "example_key"                                   # Name for new SSH key or for existing SSH key
  ssh_private_key_path      = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/example_key.pem" # Path to existing SSH private key
  
  # VPC configuration
  vpc_create      = false                                                     # true - create new VPC, false - use existing VPC
  vpc_id_existing = "vpc-example"                                             # VPC ID for existing VPC

  # Security group configuration
  security_group_create      = false                                          # true - create new security group, false - use existing security group
  security_group_id_existing = "vpc-example"                                  # Security group ID for existing security group

  # Elastic IP configuration
  elastic_ip_create           = false                                         # true - create new elastic IP, false - use existing elastic IP
  elastic_ip_existing         = "1.2.3.4"                                     # Elastic IP for existing elastic IP

  # Single Red5 Pro server HTTPS/SSL certificate configuration
  https_letsencrypt_enable                   = true                           # true - create new Let's Encrypt HTTPS/SSL certificate, false - use Red5 Pro server without HTTPS/SSL certificate
  https_letsencrypt_certificate_domain_name  = "red5pro.example.com"          # Domain name for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_email        = "email@example.com"            # Email for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_password     = "examplepass"                  # Password for Let's Encrypt SSL certificate
  
  # Single Red5 Pro server EC2 instance configuration
  single_instance_type = "t2.medium"                                                 # Instance type for Red5 Pro server
  single_volume_size   = 8                                                           # Volume size for Red5 Pro server

  # Red5Pro server configuration
  red5pro_license_key            = "1111-2222-3333-4444"                      # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_api_enable             = true                                       # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/#gatsby-focus-wrapper)
  red5pro_api_key                = "examplekey"                               # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/#gatsby-focus-wrapper)
  red5pro_inspector_enable       = false                                      # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  red5pro_restreamer_enable      = false                                      # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  red5pro_socialpusher_enable    = false                                      # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  red5pro_suppressor_enable      = false                                      # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  red5pro_hls_enable             = false                                      # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  red5pro_round_trip_auth_enable = false                                      # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)
  
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

## Red5 Pro Stream Manager cluster deployment (cluster) - [Example](https://github.com/red5pro/terraform-aws-red5pro/tree/master/examples/cluster)

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
* Autoscaling node group using API to Stream Manager (optional) - (https://www.red5pro.com/docs/special/concepts/nodegroup/)

## Usage (cluster)

```hcl
module "red5pro" {
  source  = "red5pro/red5pro/aws"

  type = "cluster"                                                            # Deployment type: single, cluster, autoscaling
  name = "red5pro-cluster"                                                    # Name to be used on all the resources as identifier

  path_to_red5pro_build        = "./red5pro-server-11.0.0.b835-release.zip"   # Absolute path or relative path to Red5 Pro server ZIP file
  path_to_aws_cloud_controller = "./aws-cloud-controller-11.1.0.jar"          # Absolute path or relative path to AWS Cloud Controller JAR file

  # AWS authetification variables it use for Stream Manager autoscaling configuration
  aws_region     = "us-west-1"                                               # AWS region 
  aws_access_key = ""                                                        # AWS IAM Access key
  aws_secret_key = ""                                                        # AWS IAM Secret key

  # SSH key configuration
  ssh_key_create          = false                                             # true - create new SSH key, false - use existing SSH key
  ssh_key_name            = "example_key"                                     # Name for new SSH key or for existing SSH key
  ssh_private_key_path    = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/example_key.pem" # Path to existing SSH private key
  
  # VPC configuration
  vpc_create              = false                                             # true - create new VPC, false - use existing VPC
  vpc_id_existing         = "vpc-001"                                         # VPC ID for existing VPC

  # MySQL DB configuration
  mysql_rds_create        = false                                             # true - create new RDS instance, false - install local MySQL server on the Stream Manager EC2 instance
  mysql_rds_instance_type = "db.t2.micro"                                     # Instance type for RDS instance
  mysql_user_name         = "exampleuser"                                     # MySQL user name
  mysql_password          = "examplepass"                                     # MySQL password
  mysql_port              = 3306                                              # MySQL port

  # Stream Manager Elastic IP configuration
  elastic_ip_create       = false                                             # true - create new elastic IP, false - use existing elastic IP
  elastic_ip_existing     = "1.2.3.4"                                         # Elastic IP for existing elastic IP

  # Stream Manager HTTPS/SSL certificate configuration
  https_letsencrypt_enable                   = true                           # true - create new Let's Encrypt HTTPS/SSL certificate, false - use Red5 Pro server without HTTPS/SSL certificate
  https_letsencrypt_certificate_domain_name  = "red5pro.example.com"          # Domain name for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_email        = "email@example.com"            # Email for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_password     = "examplepass"                  # Password for Let's Encrypt SSL certificate

  # Stream Manager configuration 
  stream_manager_instance_type  = "t3.medium"                                 # Instance type for Stream Manager
  stream_manager_volume_size    = 20                                          # Volume size for Stream Manager
  stream_manager_api_key        = "examplekey"                                    # API key for Stream Manager

  # Red5 Pro general configuration
  red5pro_license_key           = "1111-2222-3333-4444"                       # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_cluster_key           = "examplekey"                                # Red5 Pro cluster key
  red5pro_api_enable            = true                                        # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/#gatsby-focus-wrapper)
  red5pro_api_key               = "examplekey"                                # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/#gatsby-focus-wrapper)

  # Red5 Pro autoscaling Origin node image configuration
  origin_image_create                             = true                      # Default: true for Autoscaling and Cluster, true - create new Origin node image, false - not create new Origin node image
  origin_image_instance_type                      = "t3.medium"               # Instance type for Origin node image
  origin_image_volume_size                        = 8                         # Volume size for Origin node image
  origin_image_red5pro_inspector_enable           = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  origin_image_red5pro_restreamer_enable          = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  origin_image_red5pro_socialpusher_enable        = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  origin_image_red5pro_suppressor_enable          = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  origin_image_red5pro_hls_enable                 = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  origin_image_red5pro_round_trip_auth_enable     = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Edge node image configuration - (Optional)
  edge_image_create                               = false                     # true - create new Edge node image, false - not create new Edge node image
  edge_image_instance_type                        = "t3.medium"               # Instance type for Edge node image
  edge_image_volume_size                          = 8                         # Volume size for Edge node image
  edge_image_red5pro_inspector_enable             = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  edge_image_red5pro_restreamer_enable            = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  edge_image_red5pro_socialpusher_enable          = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  edge_image_red5pro_suppressor_enable            = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  edge_image_red5pro_hls_enable                   = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  edge_image_red5pro_round_trip_auth_enable       = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Transcoder node image configuration - (Optional)
  transcoder_image_create                         = false                     # true - create new Transcoder node image, false - not create new Transcoder node image
  transcoder_image_instance_type                  = "t3.medium"               # Instance type for Transcoder node image
  transcoder_image_volume_size                    = 8                         # Volume size for Transcoder node image
  transcoder_image_red5pro_inspector_enable       = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  transcoder_image_red5pro_restreamer_enable      = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  transcoder_image_red5pro_socialpusher_enable    = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  transcoder_image_red5pro_suppressor_enable      = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  transcoder_image_red5pro_hls_enable             = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  transcoder_image_red5pro_round_trip_auth_enable = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Relay node image configuration - (Optional)
  relay_image_create                              = false                     # true - create new Relay node image, false - not create new Relay node image
  relay_image_instance_type                       = "t3.medium"               # Instance type for Relay node image
  relay_image_volume_size                         = 8                         # Volume size for Relay node image
  relay_image_red5pro_inspector_enable            = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  relay_image_red5pro_restreamer_enable           = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  relay_image_red5pro_socialpusher_enable         = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  relay_image_red5pro_suppressor_enable           = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  relay_image_red5pro_hls_enable                  = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  relay_image_red5pro_round_trip_auth_enable      = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Node group - (Optional)
  node_group_create                               = true                      # Linux or Mac OS only. true - create new Node group, false - not create new Node group
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

## Red5 Pro Stream Manager cluster with AWS autoscaling Stream Managers (autoscaling) - [Example](https://github.com/red5pro/terraform-aws-red5pro/tree/master/examples/autoscaling)

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
* Autoscaling node group using API to Stream Manager (optional) - (https://www.red5pro.com/docs/special/concepts/nodegroup/)

## Usage (autoscaling)

```hcl
module "red5pro" {
  source  = "red5pro/red5pro/aws"

  type = "autoscaling"                                                        # Deployment type: single, cluster, autoscaling
  name = "red5pro-auto"                                                       # Name to be used on all the resources as identifier

  path_to_red5pro_build        = "./red5pro-server-11.0.0.b835-release.zip"   # Absolute path or relative path to Red5 Pro server ZIP file
  path_to_aws_cloud_controller = "./aws-cloud-controller-11.1.0.jar"          # Absolute path or relative path to AWS Cloud Controller JAR file

  # AWS authetification variables it use for Stream Manager autoscaling configuration
  aws_region     = "us-west-1"                                               # AWS region 
  aws_access_key = ""                                                        # AWS IAM Access key
  aws_secret_key = ""                                                        # AWS IAM Secret key

  # SSH key configuration
  ssh_key_create          = false                                             # true - create new SSH key, false - use existing SSH key
  ssh_key_name            = "example_key"                                     # Name for new SSH key or for existing SSH key
  ssh_private_key_path    = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/example_key.pem" # Path to existing SSH private key
  
  # VPC configuration
  vpc_create              = false                                             # true - create new VPC, false - use existing VPC
  vpc_id_existing         = "vpc-001"                                         # VPC ID for existing VPC

  # MySQL DB configuration
  mysql_rds_instance_type = "db.t2.micro"                                     # Instance type for RDS instance
  mysql_user_name         = "exampleuser"                                     # MySQL user name
  mysql_password          = "examplepass"                                     # MySQL password
  mysql_port              = 3306                                              # MySQL port

  # Load Balancer HTTPS/SSL certificate configuration
  https_certificate_manager_use_existing     = true                           # If you want to use SSL certificate set it to true
  https_certificate_manager_certificate_name = "red5pro.example.com"          # Domain name for your SSL certificate

  # Stream Manager configuration 
  stream_manager_instance_type                = "t3.medium"                   # Instance type for Stream Manager
  stream_manager_volume_size                  = 20                            # Volume size for Stream Manager
  stream_manager_api_key                      = "examplekey"                  # API key for Stream Manager
  stream_manager_autoscaling_desired_capacity = 1                             # Desired capacity for Stream Manager autoscaling group
  stream_manager_autoscaling_minimum_capacity = 1                             # Minimum capacity for Stream Manager autoscaling group
  stream_manager_autoscaling_maximum_capacity = 1                             # Maximum capacity for Stream Manager autoscaling group

  # Red5 Pro general configuration
  red5pro_license_key           = "1111-2222-3333-4444"                       # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_cluster_key           = "examplekey"                                # Red5 Pro cluster key
  red5pro_api_enable            = true                                        # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/#gatsby-focus-wrapper)
  red5pro_api_key               = "examplekey"                                # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/#gatsby-focus-wrapper)

  # Red5 Pro autoscaling Origin node image configuration
  origin_image_create                             = true                      # Default: true for Autoscaling and Cluster, true - create new Origin node image, false - not create new Origin node image
  origin_image_instance_type                      = "t3.medium"               # Instance type for Origin node image
  origin_image_volume_size                        = 8                         # Volume size for Origin node image
  origin_image_red5pro_inspector_enable           = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  origin_image_red5pro_restreamer_enable          = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  origin_image_red5pro_socialpusher_enable        = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  origin_image_red5pro_suppressor_enable          = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  origin_image_red5pro_hls_enable                 = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  origin_image_red5pro_round_trip_auth_enable     = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Edge node image configuration - (Optional)
  edge_image_create                               = false                     # true - create new Edge node image, false - not create new Edge node image
  edge_image_instance_type                        = "t3.medium"               # Instance type for Edge node image
  edge_image_volume_size                          = 8                         # Volume size for Edge node image
  edge_image_red5pro_inspector_enable             = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  edge_image_red5pro_restreamer_enable            = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  edge_image_red5pro_socialpusher_enable          = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  edge_image_red5pro_suppressor_enable            = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  edge_image_red5pro_hls_enable                   = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  edge_image_red5pro_round_trip_auth_enable       = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Transcoder node image configuration - (Optional)
  transcoder_image_create                         = false                     # true - create new Transcoder node image, false - not create new Transcoder node image
  transcoder_image_instance_type                  = "t3.medium"               # Instance type for Transcoder node image
  transcoder_image_volume_size                    = 8                         # Volume size for Transcoder node image
  transcoder_image_red5pro_inspector_enable       = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  transcoder_image_red5pro_restreamer_enable      = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  transcoder_image_red5pro_socialpusher_enable    = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  transcoder_image_red5pro_suppressor_enable      = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  transcoder_image_red5pro_hls_enable             = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  transcoder_image_red5pro_round_trip_auth_enable = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Relay node image configuration - (Optional)
  relay_image_create                              = false                     # true - create new Relay node image, false - not create new Relay node image
  relay_image_instance_type                       = "t3.medium"               # Instance type for Relay node image
  relay_image_volume_size                         = 8                         # Volume size for Relay node image
  relay_image_red5pro_inspector_enable            = false                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/#gatsby-focus-wrapper)
  relay_image_red5pro_restreamer_enable           = false                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/#gatsby-focus-wrapper)
  relay_image_red5pro_socialpusher_enable         = false                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/#gatsby-focus-wrapper)
  relay_image_red5pro_suppressor_enable           = false                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  relay_image_red5pro_hls_enable                  = false                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/#gatsby-focus-wrapper)
  relay_image_red5pro_round_trip_auth_enable      = false                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)

  # Red5 Pro autoscaling Node group - (Optional)
  node_group_create                               = true                      # Linux or Mac OS only. true - create new Node group, false - not create new Node group
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

**NOTES**

* To activate HTTPS/SSL you need to add DNS A record for Elastic IP (single/cluster) or CNAME record for Load Balancer DNS name (autoscaling)

---


## Future updates

* Add logic to validate existing Security group (open ports)
* Add Monitoring tools
* Add Mixer parts

---
