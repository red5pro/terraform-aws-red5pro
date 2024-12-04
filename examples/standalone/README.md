# Standalone Red5 Pro Server (standalone)

This module automates the infrastructure provisioning of the [Red5 Pro standalone server](https://www.red5.net/docs/installation/) on AWS using Terraform.

## Terraform Deployed Resources (standalone)

- VPC
- Public Subnet
- Internet Gateway
- Route Table
- Security Groups for Standalone Red5 Pro Server
- SSH Key Pair (use existing or create a new one)
- Standalone Red5 Pro Server Instance
- SSL Certificate for Standalone Red5 Pro Server Instance. Options:
  - `none`: Red5 Pro server without HTTPS and SSL certificate. Only HTTP on port `5080`
  - `letsencrypt`: Red5 Pro server with HTTPS and SSL certificate obtained by Let's Encrypt. HTTP on port `5080`, HTTPS on port `443`
  - `imported`: Red5 Pro server with HTTPS and imported SSL certificate. HTTP on port `5080`, HTTPS on port `443`

## Example `main.tf` (standalone)

```yaml

# Example: Red5 Pro Standalone Deployment
##################################################################################################################
provider "aws" {
  region     = "us-east-1"
  access_key = "your_access_key_id"
  secret_key = "your_secret_access_key"
}

module "red5pro" {
  source                = "../../"
  type                  = "standalone"                            # Deployment type: standalone, cluster, autoscale
  name                  = "red5pro-standalone"                    # Name to be used on all the resources as identifier
  path_to_red5pro_build = "./red5pro-server-0.0.0.b0-release.zip" # Absolute path or relative path to Red5 Pro server ZIP file

  # SSH key configuration
  ssh_key_use_existing              = false                                              # true - use existing SSH key, false - create new SSH key
  ssh_key_existing_private_key_path = "/PATH/TO/SSH/PRIVATE/KEY/example_private_key.pem" # Path to existing SSH private key
  ssh_key_existing_public_key_path  = "/PATH/TO/SSH/PUBLIC/KEY/example_pub_key.pem"      # Path to existing SSH Public key

 # Red5 Pro general configuration
  red5pro_license_key = "1111-2222-3333-4444" # Red5 Pro license key (https://account.red5.net/login)
  red5pro_api_enable  = true                  # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5.net/docs/development/api/overview/)  
  red5pro_api_key     = "example_key"         # Red5 Pro server API key (https://www.red5.net/docs/development/api/overview/)

  # Standalone Red5 Pro server AWS instance configuration
  standalone_red5pro_instance_type   = "t3.medium" # Instance type for Red5 Pro server 
  standalone_red5pro_instance_volume = 50         # Volume size in GB for Red5 Pro server instance

  # Standalone Red5 Pro server configuration
  standalone_red5pro_inspector_enable                    = false                         # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5.net/docs/troubleshooting/inspector/overview/)
  standalone_red5pro_restreamer_enable                   = false                         # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5.net/docs/special/restreamer/overview/)
  standalone_red5pro_socialpusher_enable                 = false                         # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5.net/docs/special/social-media-plugin/overview/)
  standalone_red5pro_suppressor_enable                   = false 
# true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  standalone_red5pro_hls_enable                          = false                         # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5.net/docs/protocols/hls-plugin/hls-vod/)
  standalone_red5pro_round_trip_auth_enable              = false                         # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5.net/docs/special/round-trip-auth/overview/)
  standalone_red5pro_round_trip_auth_host                = "round-trip-auth.example.com" # Round trip authentication server host
  standalone_red5pro_round_trip_auth_port                = 3000                          # Round trip authentication server port
  standalone_red5pro_round_trip_auth_protocol            = "http"                        # Round trip authentication server protocol
  standalone_red5pro_round_trip_auth_endpoint_validate   = "/validateCredentials"        # Round trip authentication server endpoint for validate
  standalone_red5pro_round_trip_auth_endpoint_invalidate = "/invalidateCredentials"      # Round trip authentication server endpoint for invalidate

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
}

output "module_output" {
  value = module.red5pro
}
```
