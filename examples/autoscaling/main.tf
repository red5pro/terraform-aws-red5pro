####################################################################################
# Example for Red5 Pro Stream Manager cluster with AWS autoscaling Stream Managers #
####################################################################################

provider "aws" {
  region     = "us-west-1"                                                    # AWS region
  access_key = ""                                                             # AWS IAM Access key
  secret_key = ""                                                             # AWS IAM Secret key
}

module "red5pro" {
  source  = "../../"

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
  origin_image_red5pro_webhooks_enable                      = false                               # true - enable Red5 Pro server webhooks, false - disable Red5 Pro server webhooks (https://www.red5.net/docs/special/webhooks/overview/)
  origin_image_red5pro_webhooks_endpoint                    = "https://example.com/red5/status"   # Red5 Pro server webhooks endpoint
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

variable "origin_image_red5pro_webhooks_enable" {
  description = "Origin node image - Webhooks enable/disable (https://www.red5.net/docs/special/webhooks/overview/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_webhooks_endpoint" {
  description = "Origin node image - Webhooks endpoint"
  type        = string
  default     = ""
}


  # Red5 Pro autoscaling Node group - (Optional)
  node_group_create                               = true                      # Linux or Mac OS only. true - create new Node group, false - not create new Node group
  node_group_name                                 = "terraform-node-group"    # Node group name
  # Origin node configuration
  node_group_origins                              = 1                         # Number of Origins
  node_group_origins_instance_type                = "t3.medium"               # Instance type for Origins
  node_group_origins_capacity                     = 20                        # Connections capacity for Origins
  # Edge node configuration
  node_group_edges                                = 1                         # Number of Edges
  node_group_edges_instance_type                  = "t3.medium"               # Instance type for Edges
  node_group_edges_capacity                       = 200                       # Connections capacity for Edges
  # Transcoder node configuration
  node_group_transcoders                          = 0                         # Number of Transcoders
  node_group_transcoders_instance_type            = "t3.medium"               # Instance type for Transcoders
  node_group_transcoders_capacity                 = 20                        # Connections capacity for Transcoders
  # Relay node configuration
  node_group_relays                               = 0                         # Number of Relays
  node_group_relays_instance_type                 = "t3.medium"               # Instance type for Relays
  node_group_relays_capacity                      = 20                        # Connections capacity for Relays

  # Red5 Pro tags configuration - it will be added to all Red5 Pro resources
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "red5pro"
  }
}

