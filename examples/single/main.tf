#################################################
# Example for single Red5 Pro server deployment #
#################################################

provider "aws" {
  region     = "us-west-1"                                                        # AWS region
  access_key = ""                                                                 # AWS IAM Access key
  secret_key = ""                                                                 # AWS IAM Secret key
}

module "red5pro" {
  source  = "../../"

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
  red5pro_webhooks_enable                       = false                                      # true - enable Red5 Pro server webhooks, false - disable Red5 Pro server webhooks (https://www.red5.net/docs/special/webhooks/overview/)
  red5pro_webhooks_endpoint                     = "https://example.com/red5/status"          # Red5 Pro server webhooks endpoint
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
