# AWS Red5 Pro Terraform module

Terraform Red5 Pro AWS module which create Red5 Pro resources on AWS.

## This module has 4 variants of Red5 Pro deployments

* **single** - Single EC2 instance with installed and configured Red5 Pro server
* **cluster** - Stream Manager cluster (MySQL DB + Stream Manager instance + Autoscaling Node group with Origin, Edge, Transcoder, Relay instances)
* **autoscaling** - Autoscaling Stream Managers (MySQL RDS + Load Balancer + Autoscaling Stream Managers + Autoscaling Node group with Origin, Edge, Transcoder, Relay instances)
* **vpc** - VPC only (VPC, Sunbets, Route table, Internet Gateway) - this option is useful if you need to create VPC separately and after that use this VPC to deploy Red5 Pro resources

---

## Preparation

* Install **terraform** https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
* Install **AWS CLI** https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
* Install **jq** Linux or Mac OS only - `apt install jq` or `brew install jq` (It is using in bash scripts to create/delete Stream Manager node group using API)
* Download Red5 Pro server build: (Example: red5pro-server-0.0.0.b0-release.zip) https://account.red5.net/downloads
* Download Red5 Pro Autoscale controller for AWS: (Example: aws-cloud-controller-0.0.0.jar) https://account.red5.net/downloads
* Get Red5 Pro License key: (Example: 1111-2222-3333-4444) https://account.red5.net
* Get AWS Access key and AWS Secret key or use existing (AWS IAM - EC2 full access, RDS full access, VPC full access, Certificate manager read only)
* Copy Red5 Pro server build and Red5 Pro Autoscale controller for AWS to the root folder of your project

Example:  

```bash
cp ~/Downloads/red5pro-server-0.0.0.b0-release.zip ./
cp ~/Downloads/aws-cloud-controller-0.0.0.jar ./
```

## Single Red5 Pro server deployment (single) - [Example](https://github.com/red5pro/terraform-aws-red5pro/tree/master/examples/single)

* VPC create or use existing
* Elastic IP create or use existing
* Security group create or use existing
* SSH key create or use existing
* SSL certificate install Let's encrypt or use Red5Pro server without SSL certificate (HTTP only)

## Usage (single)

```hcl
provider "aws" {
  region     = "us-west-1"                                                        # AWS region
  access_key = ""                                                                 # AWS IAM Access key
  secret_key = ""                                                                 # AWS IAM Secret key
}

module "red5pro" {
  source  = "red5pro/red5pro/aws"

  type    = "single"                                                              # Deployment type: single, cluster, autoscaling
  name    = "red5pro-single"                                                      # Name to be used on all the resources as identifier

  ubuntu_version            = "22.04"                                             # Ubuntu version for Red5 Pro servers
  path_to_red5pro_build     = "./red5pro-server-0.0.0.b0-release.zip"             # Absolute path or relative path to Red5 Pro server ZIP file

    # SSH key configuration
  ssh_key_create            = true                                                # true - create new SSH key, false - use existing SSH key
  ssh_key_name              = "example_key"                                       # Name for new SSH key or for existing SSH key
  ssh_private_key_path      = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/example_key.pem" # Path to existing SSH private key
  
  # VPC configuration
  vpc_create      = true                                                          # true - create new VPC, false - use existing VPC
  vpc_id_existing = "vpc-12345"                                                   # VPC ID for existing VPC

  # Security group configuration
  security_group_create      = true                                               # true - create new security group, false - use existing security group
  security_group_id_existing = "sg-12345"                                         # Security group ID for existing security group

  # Elastic IP configuration
  elastic_ip_create           = true                                              # true - create new elastic IP, false - use existing elastic IP
  elastic_ip_existing         = "1.2.3.4"                                         # Elastic IP for existing elastic IP

  # Single Red5 Pro server HTTPS/SSL certificate configuration
  https_letsencrypt_enable                   = true                               # true - create new Let's Encrypt HTTPS/SSL certificate, false - use Red5 Pro server without HTTPS/SSL certificate
  https_letsencrypt_certificate_domain_name  = "red5pro.example.com"              # Domain name for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_email        = "email@example.com"                # Email for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_password     = "examplepass"                      # Password for Let's Encrypt SSL certificate
  
  # Single Red5 Pro server EC2 instance configuration
  single_instance_type                       = "t3.medium"                        # Instance type for Red5 Pro server
  single_volume_size                         = 8                                  # Volume size for Red5 Pro server

  # Red5Pro server configuration
  red5pro_license_key                           = "1111-2222-3333-4444"                      # Red5 Pro license key (https://account.red5.net/login)
  red5pro_api_enable                            = true                                       # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5.net/docs/development/api/overview/)
  red5pro_api_key                               = "examplekey"                               # Red5 Pro server API key (https://www.red5.net/docs/development/api/overview/)
  red5pro_inspector_enable                      = false                                      # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5.net/docs/troubleshooting/inspector/overview/)
  red5pro_restreamer_enable                     = false                                      # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5.net/docs/special/restreamer/overview/)
  red5pro_socialpusher_enable                   = false                                      # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5.net/docs/special/social-media-plugin/overview/)
  red5pro_suppressor_enable                     = false                                      # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  red5pro_hls_enable                            = false                                      # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5.net/docs/protocols/hls-plugin/hls-vod/)
  red5pro_round_trip_auth_enable                = false                                      # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5.net/docs/special/round-trip-auth/overview/)
  red5pro_round_trip_auth_host                  = "round-trip-auth.example.com"              # Round trip authentication server host
  red5pro_round_trip_auth_port                  = 3000                                       # Round trip authentication server port
  red5pro_round_trip_auth_protocol              = "http"                                     # Round trip authentication server protocol
  red5pro_round_trip_auth_endpoint_validate     = "/validateCredentials"                     # Round trip authentication server endpoint for validate
  red5pro_round_trip_auth_endpoint_invalidate   = "/invalidateCredentials"                   # Round trip authentication server endpoint for invalidate
  red5pro_cloudstorage_enable                   = false                                      # true - enable Red5 Pro server cloud storage, false - disable Red5 Pro server cloud storage (https://www.red5.net/docs/special/cloudstorage-plugin/aws-s3-cloud-storage/)
  red5pro_cloudstorage_aws_access_key           = ""                                         # AWS access key for Red5 Pro cloud storage (S3 Bucket)
  red5pro_cloudstorage_aws_secret_key           = ""                                         # AWS secret key for Red5 Pro cloud storage (S3 Bucket)
  red5pro_cloudstorage_aws_bucket_name          = "s3-bucket-example-name"                   # AWS bucket name for Red5 Pro cloud storage (S3 Bucket)
  red5pro_cloudstorage_aws_region               = "us-west-1"                                # AWS region for Red5 Pro cloud storage  (S3 Bucket)
  red5pro_cloudstorage_postprocessor_enable     = false                                      # true - enable Red5 Pro server postprocessor, false - disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)
  red5pro_cloudstorage_aws_bucket_acl_policy    = "public-read"                              # AWS bucket ACL policy for Red5 Pro cloud storage (S3 Bucket) Example: none, public-read, authenticated-read, private, public-read-write
  red5pro_coturn_enable                         = false                                      # true - enable customized Coturn configuration for Red5Pro server, false - disable customized Coturn configuration for Red5Pro server (https://www.red5.net/docs/installation/turn-stun/turnstun/)
  red5pro_coturn_address                        = "stun:1.2.3.4:3478"                        # Customized coturn address for Red5Pro server (https://www.red5.net/docs/installation/turn-stun/turnstun/)
  red5pro_efs_enable                            = false                                      # enable/disable EFS mount to record streams
  red5pro_efs_dns_name                          = "example.efs.region.amazonaws.com"         # EFS DNS name

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
* Autoscaling node group using API to Stream Manager (optional) - (https://www.red5.net/docs/special/concepts/nodegroup/)

## Usage (cluster)

```hcl
provider "aws" {
  region     = "us-west-1"                                                    # AWS region
  access_key = ""                                                             # AWS IAM Access key
  secret_key = ""                                                             # AWS IAM Secret key
}

module "red5pro" {
  source  = "red5pro/red5pro/aws"

  type    = "cluster"                                                         # Deployment type: single, cluster, autoscaling
  name    = "red5pro-cluster"                                                 # Name to be used on all the resources as identifier

  ubuntu_version               = "22.04"                                      # Ubuntu version for Red5 Pro servers
  path_to_red5pro_build        = "./red5pro-server-0.0.0.b0-release.zip"      # Absolute path or relative path to Red5 Pro server ZIP file
  path_to_aws_cloud_controller = "./aws-cloud-controller-0.0.0.jar"           # Absolute path or relative path to AWS Cloud Controller JAR file

  # AWS authetification variables it use for Stream Manager autoscaling configuration
  aws_region     = "us-west-1"                                                # AWS region 
  aws_access_key = ""                                                         # AWS IAM Access key
  aws_secret_key = ""                                                         # AWS IAM Secret key

  # SSH key configuration
  ssh_key_create          = true                                              # true - create new SSH key, false - use existing SSH key
  ssh_key_name            = "example_key"                                     # Name for new SSH key or for existing SSH key
  ssh_private_key_path    = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/example_key.pem" # Path to existing SSH private key
  
  # VPC configuration
  vpc_create              = true                                              # true - create new VPC, false - use existing VPC
  vpc_id_existing         = "vpc-12345"                                       # VPC ID for existing VPC

  # MySQL DB configuration
  mysql_rds_create        = false                                             # true - create new RDS instance, false - install local MySQL server on the Stream Manager EC2 instance
  mysql_rds_instance_type = "db.t2.micro"                                     # Instance type for RDS instance
  mysql_user_name         = "exampleuser"                                     # MySQL user name
  mysql_password          = "examplepass"                                     # MySQL password
  mysql_port              = 3306                                              # MySQL port

  # Stream Manager Elastic IP configuration
  elastic_ip_create       = true                                              # true - create new elastic IP, false - use existing elastic IP
  elastic_ip_existing     = "1.2.3.4"                                         # Elastic IP for existing elastic IP

  # Stream Manager HTTPS/SSL certificate configuration
  https_letsencrypt_enable                   = true                           # true - create new Let's Encrypt HTTPS/SSL certificate, false - use Red5 Pro server without HTTPS/SSL certificate
  https_letsencrypt_certificate_domain_name  = "red5pro.example.com"          # Domain name for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_email        = "email@example.com"            # Email for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_password     = "examplepass"                  # Password for Let's Encrypt SSL certificate

  # Stream Manager configuration 
  stream_manager_instance_type  = "t3.medium"                                 # Instance type for Stream Manager
  stream_manager_volume_size    = 20                                          # Volume size for Stream Manager
  stream_manager_api_key        = "examplekey"                                # API key for Stream Manager
  stream_manager_coturn_enable  = false                                       # true - enable customized Coturn configuration for Stream Manager, false - disable customized Coturn configuration for Stream Manager (https://www.red5.net/docs/installation/turn-stun/turnstun/)
  stream_manager_coturn_address = "stun:1.2.3.4:3478"                         # Customized coturn address for Stream Manager (https://www.red5.net/docs/installation/turn-stun/turnstun/)

  # Red5 Pro general configuration
  red5pro_license_key           = "1111-2222-3333-4444"                       # Red5 Pro license key (https://account.red5.net/login)
  red5pro_cluster_key           = "examplekey"                                # Red5 Pro cluster key
  red5pro_api_enable            = true                                        # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5.net/docs/development/api/overview/)
  red5pro_api_key               = "examplekey"                                # Red5 Pro server API key (https://www.red5.net/docs/development/api/overview/)

  # Red5 Pro autoscaling Origin node image configuration
  origin_image_create                                       = true                          # Default: true for Autoscaling and Cluster, true - create new Origin node image, false - not create new Origin node image
  origin_image_instance_type                                = "t3.medium"                         # Instance type for Origin node image
  origin_image_volume_size                                  = 8                                   # Volume size for Origin node image
  origin_image_red5pro_inspector_enable                     = false                               # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5.net/docs/troubleshooting/inspector/overview/)
  origin_image_red5pro_restreamer_enable                    = false                               # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5.net/docs/special/restreamer/overview/)
  origin_image_red5pro_socialpusher_enable                  = false                               # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5.net/docs/special/social-media-plugin/overview/)
  origin_image_red5pro_suppressor_enable                    = false                               # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  origin_image_red5pro_hls_enable                           = false                               # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5.net/docs/protocols/hls-plugin/hls-vod/)
  origin_image_red5pro_round_trip_auth_enable               = false                               # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5.net/docs/special/round-trip-auth/overview/)
  origin_image_red5pro_round_trip_auth_host                 = "round-trip-auth.example.com"       # Round trip authentication server host
  origin_image_red5pro_round_trip_auth_port                 = 3000                                # Round trip authentication server port
  origin_image_red5pro_round_trip_auth_protocol             = "http"                              # Round trip authentication server protocol
  origin_image_red5pro_round_trip_auth_endpoint_validate    = "/validateCredentials"              # Round trip authentication server endpoint for validate
  origin_image_red5pro_round_trip_auth_endpoint_invalidate  = "/invalidateCredentials"            # Round trip authentication server endpoint for invalidate
  origin_image_red5pro_cloudstorage_enable                  = false                               # true - enable Red5 Pro server cloud storage, false - disable Red5 Pro server cloud storage (https://www.red5.net/docs/special/cloudstorage-plugin/aws-s3-cloud-storage/)
  origin_image_red5pro_cloudstorage_aws_access_key          = ""                                  # AWS access key for Red5 Pro cloud storage (S3 Bucket)
  origin_image_red5pro_cloudstorage_aws_secret_key          = ""                                  # AWS secret key for Red5 Pro cloud storage (S3 Bucket)
  origin_image_red5pro_cloudstorage_aws_bucket_name         = "s3-bucket-example-name"            # AWS bucket name for Red5 Pro cloud storage (S3 Bucket)
  origin_image_red5pro_cloudstorage_aws_region              = "us-west-1"                         # AWS region for Red5 Pro cloud storage  (S3 Bucket)
  origin_image_red5pro_cloudstorage_postprocessor_enable    = false                               # true - enable Red5 Pro server postprocessor, false - disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)
  origin_image_red5pro_cloudstorage_aws_bucket_acl_policy   = "public-read"                       # AWS bucket ACL policy for Red5 Pro cloud storage (S3 Bucket) Example: none, public-read, authenticated-read, private, public-read-write
  origin_image_red5pro_efs_enable                           = false                               # enable/disable EFS mount to record streams
  origin_image_red5pro_efs_dns_name                         = "example.efs.region.amazonaws.com"  # EFS DNS name


  # Red5 Pro autoscaling Node group - (Optional)
  node_group_create                               = true                      # Linux or Mac OS only. true - create new Node group, false - not create new Node group
  node_group_name                                 = "terraform-node-group"    # Node group name
  # Origin node configuration
  node_group_origins_min                          = 1                         # Number of minimum Origins
  node_group_origins_max                          = 20                        # Number of maximum Origins
  node_group_origins_instance_type                = "t3.medium"               # Instance type for Origins
  node_group_origins_capacity                     = 20                        # Connections capacity for Origins
  # Edge node configuration
  node_group_edges_min                            = 1                         # Number of minimum Edges
  node_group_edges_max                            = 40                        # Number of maximum Edges
  node_group_edges_instance_type                  = "t3.medium"               # Instance type for Edges
  node_group_edges_capacity                       = 200                       # Connections capacity for Edges
  # Transcoder node configuration
  node_group_transcoders_min                      = 0                         # Number of minimum Transcoders
  node_group_transcoders_max                      = 20                        # Number of maximum Transcoders
  node_group_transcoders_instance_type            = "t3.medium"               # Instance type for Transcoders
  node_group_transcoders_capacity                 = 20                        # Connections capacity for Transcoders
  # Relay node configuration
  node_group_relays_min                           = 0                         # Number of minimum Relays
  node_group_relays_max                           = 20                        # Number of maximum Relays
  node_group_relays_instance_type                 = "t3.medium"               # Instance type for Relays
  node_group_relays_capacity                      = 20                        # Connections capacity for Relays
  
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
* Autoscaling node group using API to Stream Manager (optional) - (https://www.red5.net/docs/special/concepts/nodegroup/)

## Usage (autoscaling)

```hcl
provider "aws" {
  region     = "us-west-1"                                                    # AWS region
  access_key = ""                                                             # AWS IAM Access key
  secret_key = ""                                                             # AWS IAM Secret key
}

module "red5pro" {
  source  = "red5pro/red5pro/aws"

  type    = "autoscaling"                                                        # Deployment type: single, cluster, autoscaling
  name    = "red5pro-auto"                                                       # Name to be used on all the resources as identifier

  ubuntu_version               = "22.04"                                      # Ubuntu version for Red5 Pro servers
  path_to_red5pro_build        = "./red5pro-server-0.0.0.b0-release.zip"      # Absolute path or relative path to Red5 Pro server ZIP file
  path_to_aws_cloud_controller = "./aws-cloud-controller-0.0.0.jar"           # Absolute path or relative path to AWS Cloud Controller JAR file

  # AWS authetification variables it use for Stream Manager autoscaling configuration
  aws_region     = "us-west-1"                                                # AWS region 
  aws_access_key = ""                                                         # AWS IAM Access key
  aws_secret_key = ""                                                         # AWS IAM Secret key

  # SSH key configuration
  ssh_key_create          = true                                             # true - create new SSH key, false - use existing SSH key
  ssh_key_name            = "example_key"                                     # Name for new SSH key or for existing SSH key
  ssh_private_key_path    = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/example_key.pem" # Path to existing SSH private key
  
  # VPC configuration
  vpc_create              = true                                             # true - create new VPC, false - use existing VPC
  vpc_id_existing         = "vpc-12345"                                      # VPC ID for existing VPC

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
  stream_manager_coturn_enable                = false                         # true - enable customized Coturn configuration for Stream Manager, false - disable customized Coturn configuration for Stream Manager (https://www.red5.net/docs/installation/turn-stun/turnstun/)
  stream_manager_coturn_address               = "stun:1.2.3.4:3478"           # Customized coturn address for Stream Manager (https://www.red5.net/docs/installation/turn-stun/turnstun/)

  # Red5 Pro general configuration
  red5pro_license_key           = "1111-2222-3333-4444"                       # Red5 Pro license key (https://account.red5.net/login)
  red5pro_cluster_key           = "examplekey"                                # Red5 Pro cluster key
  red5pro_api_enable            = true                                        # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5.net/docs/development/api/overview/)
  red5pro_api_key               = "examplekey"                                # Red5 Pro server API key (https://www.red5.net/docs/development/api/overview/)

  # Red5 Pro autoscaling Origin node image configuration
  origin_image_create                                       = true                                # Default: true for Autoscaling and Cluster, true - create new Origin node image, false - not create new Origin node image
  origin_image_instance_type                                = "t3.medium"                         # Instance type for Origin node image
  origin_image_volume_size                                  = 8                                   # Volume size for Origin node image
  origin_image_red5pro_inspector_enable                     = false                               # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5.net/docs/troubleshooting/inspector/overview/)
  origin_image_red5pro_restreamer_enable                    = false                               # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5.net/docs/special/restreamer/overview/)
  origin_image_red5pro_socialpusher_enable                  = false                               # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5.net/docs/special/social-media-plugin/overview/)
  origin_image_red5pro_suppressor_enable                    = false                               # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  origin_image_red5pro_hls_enable                           = false                               # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5.net/docs/protocols/hls-plugin/hls-vod/)
  origin_image_red5pro_round_trip_auth_enable               = false                               # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5.net/docs/special/round-trip-auth/overview/)
  origin_image_red5pro_round_trip_auth_host                 = "round-trip-auth.example.com"       # Round trip authentication server host
  origin_image_red5pro_round_trip_auth_port                 = 3000                                # Round trip authentication server port
  origin_image_red5pro_round_trip_auth_protocol             = "http"                              # Round trip authentication server protocol
  origin_image_red5pro_round_trip_auth_endpoint_validate    = "/validateCredentials"              # Round trip authentication server endpoint for validate
  origin_image_red5pro_round_trip_auth_endpoint_invalidate  = "/invalidateCredentials"            # Round trip authentication server endpoint for invalidate
  origin_image_red5pro_cloudstorage_enable                  = false                               # true - enable Red5 Pro server cloud storage, false - disable Red5 Pro server cloud storage (https://www.red5.net/docs/special/cloudstorage-plugin/aws-s3-cloud-storage/)
  origin_image_red5pro_cloudstorage_aws_access_key          = ""                                  # AWS access key for Red5 Pro cloud storage (S3 Bucket)
  origin_image_red5pro_cloudstorage_aws_secret_key          = ""                                  # AWS secret key for Red5 Pro cloud storage (S3 Bucket)
  origin_image_red5pro_cloudstorage_aws_bucket_name         = "s3-bucket-example-name"            # AWS bucket name for Red5 Pro cloud storage (S3 Bucket)
  origin_image_red5pro_cloudstorage_aws_region              = "us-west-1"                         # AWS region for Red5 Pro cloud storage  (S3 Bucket)
  origin_image_red5pro_cloudstorage_postprocessor_enable    = false                               # true - enable Red5 Pro server postprocessor, false - disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)
  origin_image_red5pro_cloudstorage_aws_bucket_acl_policy   = "public-read"                       # AWS bucket ACL policy for Red5 Pro cloud storage (S3 Bucket) Example: none, public-read, authenticated-read, private, public-read-write
  origin_image_red5pro_efs_enable                           = false                               # enable/disable EFS mount to record streams
  origin_image_red5pro_efs_dns_name                         = "example.efs.region.amazonaws.com"  # EFS DNS name

  # Red5 Pro autoscaling Node group - (Optional)
  node_group_create                               = true                      # Linux or Mac OS only. true - create new Node group, false - not create new Node group
  node_group_name                                 = "terraform-node-group"    # Node group name
  # Origin node configuration
  node_group_origins_min                          = 1                         # Number of minimum Origins
  node_group_origins_max                          = 20                        # Number of maximum Origins
  node_group_origins_instance_type                = "t3.medium"               # Instance type for Origins
  node_group_origins_capacity                     = 20                        # Connections capacity for Origins
  # Edge node configuration
  node_group_edges_min                            = 1                         # Number of minimum Edges
  node_group_edges_max                            = 40                        # Number of maximum Edges
  node_group_edges_instance_type                  = "t3.medium"               # Instance type for Edges
  node_group_edges_capacity                       = 200                       # Connections capacity for Edges
  # Transcoder node configuration
  node_group_transcoders_min                      = 0                         # Number of minimum Transcoders
  node_group_transcoders_max                      = 20                        # Number of maximum Transcoders
  node_group_transcoders_instance_type            = "t3.medium"               # Instance type for Transcoders
  node_group_transcoders_capacity                 = 20                        # Connections capacity for Transcoders
  # Relay node configuration
  node_group_relays_min                           = 0                         # Number of minimum Relays
  node_group_relays_max                           = 20                        # Number of maximum Relays
  node_group_relays_instance_type                 = "t3.medium"               # Instance type for Relays
  node_group_relays_capacity                      = 20                        # Connections capacity for Relays

  # Red5 Pro tags configuration - it will be added to all Red5 Pro resources
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "red5pro"
  }
}
```

## AWS VPC create only (vpc) - [Example](https://github.com/red5pro/terraform-aws-red5pro/tree/master/examples/vpc)

* VPC create

## Usage (vpc)
```
provider "aws" {
  region     = "us-west-1" # AWS region
  access_key = ""          # AWS IAM Access key
  secret_key = ""          # AWS IAM Secret key
}

module "red5pro_vpc" {
  source = "red5pro/red5pro/aws"

  type = "vpc"         # Deployment type: single, cluster, autoscaling, vpc
  name = "red5pro-vpc" # Name to be used on all the resources as identifier

  # VPC configuration
  vpc_create         = true # true - create new VPC, false - use existing VPC
  vpc_cidr_block     = "10.105.0.0/16"
  vpc_public_subnets = ["10.105.0.0/24", "10.105.1.0/24", "10.105.2.0/24", "10.105.3.0/24"] # Public subnets for Stream Manager and Red5 Pro server instances

  # Red5 Pro tags configuration - it will be added to all Red5 Pro resources
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "red5pro"
  }
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
