#################################################
# Example for single Red5 Pro server deployment #
#################################################

provider "aws" {
  region     = "us-west-1"                                                    # AWS region
  access_key = ""                                                             # AWS IAM Access key
  secret_key = ""                                                             # AWS IAM Secret key
}

module "red5pro" {
  source  = "red5pro/red5pro/aws"

  type = "single"                                                            # Deployment type: single, cluster, autoscaling
  name = "red5pro-single"                                                    # Name to be used on all the resources as identifier

  path_to_red5pro_build        = "./red5pro-server-11.0.0.b835-release.zip"   # Absolute path or relative path to Red5 Pro server ZIP file
  path_to_aws_cloud_controller = "./aws-cloud-controller-11.1.0.jar"          # Absolute path or relative path to AWS Cloud Controller JAR file

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