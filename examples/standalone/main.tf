#################################################
# Example for single Red5 Pro server deployment #
#################################################

provider "aws" {
  region     = "us-east-1" # AWS region
  access_key = ""          # AWS IAM Access key
  secret_key = ""          # AWS IAM Secret key
}

module "red5pro" {
  source                = "../../"
  type                  = "standalone"                            # Deployment type: standalone, cluster, autoscale
  name                  = "red5pro-standalone"                    # Name to be used on all the resources as identifier
  path_to_red5pro_build = "./red5pro-server-0.0.0.b0-release.zip" # Absolute path or relative path to Red5 Pro server ZIP file
  ubuntu_version        = "22.04"                                 # Ubuntu version for Red5 Pro servers

  # SSH key configuration
  ssh_key_create       = false                                               # true - create new SSH key, false - use existing SSH key
  ssh_key_name         = "example_key"                                       # Name to existing SSH key
  ssh_private_key_path = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/example_key.pem" # Path to existing SSH private key

  # VPC configuration
  vpc_create      = false        # true - create new VPC, false - use existing VPC
  vpc_id_existing = "vpc-12345" # VPC ID for existing VPC

  # Elastic IP configuration
  standalone_elastic_ip_create   = false     # true - create new elastic IP, false - use existing elastic IP
  standalone_elastic_ip_existing = "1.2.3.4" # Elastic IP for existing elastic IP

  # Standalone Red5 Pro server HTTPS (SSL) certificate configuration
  https_ssl_certificate = "none" # none - do not use HTTPS/SSL certificate, letsencrypt - create new Let's Encrypt HTTPS/SSL certificate, imported - use existing HTTPS/SSL certificate

  # Example of Let's Encrypt HTTPS/SSL certificate configuration - please uncomment and provide your domain name and email
  # https_ssl_certificate = "letsencrypt"
  # https_ssl_certificate_domain_name = "red5pro.example.com"
  # https_ssl_certificate_email = "email@example.com"

  # Example of imported HTTPS/SSL certificate configuration - please uncomment and provide your domain name, certificate and key paths
  # https_ssl_certificate             = "imported"
  # https_ssl_certificate_domain_name = "red5pro.example.com"
  # https_ssl_certificate_cert_path   = "/PATH/TO/SSL/CERT/fullchain.pem"
  # https_ssl_certificate_key_path    = "/PATH/TO/SSL/KEY/privkey.pem"

  # Example of existing HTTPS/SSL certificate configuration - please uncomment and provide your domain name
  # https_ssl_certificate             = "existing"  # Use existing HTTPS/SSL certificate
  # https_ssl_certificate_domain_name = "red5pro.example.com"  # Replace with your domain name


  # Single Red5 Pro server EC2 instance configuration
  standalone_instance_type = "t3.medium" # Instance type for Red5 Pro server. Example: t3.medium, c5.large, c5.xlarge, c5.2xlarge, c5.4xlarge
  standalone_volume_size   = 16          # Volume size for Red5 Pro server

  # Red5Pro server configuration
  red5pro_license_key                                    = "1111-2222-3333-4444"             # Red5 Pro license key (https://account.red5.net/login)
  red5pro_api_enable                                     = true                              # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5.net/docs/development/api/overview/)
  red5pro_api_key                                        = "example_key"                     # Red5 Pro server API key (https://www.red5.net/docs/development/api/overview/)
  standalone_red5pro_inspector_enable                    = false                             # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5.net/docs/troubleshooting/inspector/overview/)
  standalone_red5pro_restreamer_enable                   = false                             # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5.net/docs/special/restreamer/overview/)
  standalone_red5pro_socialpusher_enable                 = false                             # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5.net/docs/special/social-media-plugin/overview/)
  standalone_red5pro_suppressor_enable                   = false                             # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  standalone_red5pro_hls_enable                          = false                             # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5.net/docs/protocols/hls-plugin/hls-vod/)
  standalone_red5pro_webhooks_enable                     = false                             # true - enable Red5 Pro server webhooks, false - disable Red5 Pro server webhooks (https://www.red5.net/docs/special/webhooks/overview/)
  standalone_red5pro_webhooks_endpoint                   = "https://example.com/red5/status" # Red5 Pro server webhooks endpoint
  standalone_red5pro_round_trip_auth_enable              = false                             # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5.net/docs/special/round-trip-auth/overview/)
  standalone_red5pro_round_trip_auth_host                = "round-trip-auth.example.com"     # Round trip authentication server host
  standalone_red5pro_round_trip_auth_port                = 3000                              # Round trip authentication server port
  standalone_red5pro_round_trip_auth_protocol            = "http"                            # Round trip authentication server protocol
  standalone_red5pro_round_trip_auth_endpoint_validate   = "/validateCredentials"            # Round trip authentication server endpoint for validate
  standalone_red5pro_round_trip_auth_endpoint_invalidate = "/invalidateCredentials"          # Round trip authentication server endpoint for invalidate

  # Red5 Pro tags configuration - it will be added to all Red5 Pro resources
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "red5pro"
  }
}

