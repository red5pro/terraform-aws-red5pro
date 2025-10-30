# Terraform Module for Deploying Red5 Pro Amazon Cloud Infrastructure (AWS) - Stream Manager 2.0

[Red5 Pro](https://www.red5.net/) is a real-time video streaming server plaform known for its low-latency streaming capabilities, making it ideal for interactive applications like online gaming, streaming events and video conferencing etc.

This is a reusable Terraform module that provisions infrastructure on [Amazon Cloud Infrastructure (AWS)](https://aws.amazon.com/console/).

## Preparation

### Install Terraform

- Visit the [Terraform download page](https://developer.hashicorp.com/terraform/downloads) and ensure you get version 1.7.5 or higher.
- Download the suitable version for your operating system.
- Extract the compressed file and copy the Terraform binary to a location within your system's PATH.
- Configure PATH for **Linux/macOS**:
  - Open a terminal and type the following command:

    ```sh
    sudo mv /path/to/terraform /usr/local/bin
    ```

- Configure PATH for **Windows**:
  - Click 'Start', search for 'Control Panel', and open it.
  - Navigate to `System > Advanced System Settings > Environment Variables`.
  - Under System variables, find 'PATH' and click 'Edit'.
  - Click 'New' and paste the directory location where you extracted the terraform.exe file.
  - Confirm changes by clicking 'OK' and close all open windows.
  - Open a new terminal and verify that Terraform has been successfully installed.

  ```sh
  terraform --version
  ```

### Install jq

- Install **jq** (Linux or Mac OS only) [Download](https://jqlang.github.io/jq/download/)
  - Linux: `apt install jq`
  - MacOS: `brew install jq`
  > It is used in bash scripts to create/delete Stream Manager node group using API

### Install bc

- Install **bc** (Linux or Mac OS only) [Download](https://www.gnu.org/software/bc/)
  - Linux: `apt install bc`
  - MacOS: `brew install bc`
  > It is used in bash scripts to create/delete Stream Manager node group using API

### Red5 Pro artifacts

- Download Red5 Pro server build in your [Red5 Pro Account](https://account.red5.net/downloads). Example: `red5pro-server-0.0.0.b0-release.zip`
- Get Red5 Pro License key in your [Red5 Pro Account](https://account.red5.net/downloads). Example: `1111-2222-3333-4444`

### Install Amazon Cloud Infrastructure (AWS) CLI

- [Installing the CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

> Install the AWS CLI on the same machine/instance where you run this Terraform module and ensure it is configured:
> - If running on AWS EC2 with an IAM instance profile, no explicit credentials are required (the CLI and providers will use the instance role automatically).
> - If running outside AWS or without an instance profile, configure a profile:
>   - `aws configure --profile myprofile`
>   - Then set `AWS_PROFILE=myprofile` (or pass `profile` in your provider if using examples).

### Prepare AWS account

- Preferred: Use IAM roles (instance profile for EC2, task role for ECS) for all Terraform and runtime operations. This module supports running entirely with instance profiles and does not require static access keys when executed on AWS.

- If static AWS access keys must be used, they must comply with the following requirements (per AWS security guidance):
  - Must only be used by humans to access AWS services and stored securely.
  - If used by a service, ALL of the conditions below must be met:
    - Not feasible to use EC2 instance role, ECS task role, or a similar mechanism.
    - Keys must be rotated at least weekly.
    - IAM policies must be tightly scoped to the minimum required permissions.
    - Access must be restricted by source IPs (deny all except Partner-approved IP addresses).
  - We strongly recommend migrating to IAM roles wherever possible to remove static credentials.

- Minimum AWS permissions this module may require (depending on selected features):
  - VPC, Subnets, Route Tables, Internet Gateways
  - EC2 Instances, AMIs, Security Groups, Key Pairs, EBS Volumes/Snapshots, Placement Groups
  - IAM to create and attach Role/Policy for Stream Manager (instance profile)
  - Autoscaling (if autoscale features are enabled)
  - Elastic Load Balancing and ACM (if HTTPS/ALB is enabled)
  - Route53 (if DNS automation is enabled)

## This module supports three variants of Red5 Pro deployments

- **standalone** - Standalone Red5 Pro server
- **cluster** - Stream Manager 2.0 cluster with autoscaling nodes
- **autoscale** - Autoscaling Stream Managers 2.0 with autoscaling nodes

### Standalone Red5 Pro server (standalone) - [Example](https://github.com/red5pro/terraform-aws-red5pro/tree/master/examples/standalone)

In the following example, Terraform module will automates the infrastructure provisioning of the [Red5 Pro standalone server](https://www.red5.net/docs/installation/).

#### Terraform Deployed Resources (standalone)

- VPC
- Public subnet
- Internet getaway
- Route table
- Security list
- Security group for Standalone Red5 Pro server
- SSH key pair (use existing or create a new one)
- Standalone Red5 Pro server instance
- SSL certificate for Standalone Red5 Pro server instance. Options:
  - `none` - Red5 Pro server without HTTPS and SSL certificate. Only HTTP on port `5080`
  - `letsencrypt` - Red5 Pro server with HTTPS and SSL certificate obtained by Let's Encrypt. HTTP on port `5080`, HTTPS on port `443`
  - `imported` - Red5 Pro server with HTTPS and imported SSL certificate. HTTP on port `5080`, HTTPS on port `443`

#### Example main.tf (standalone)

```yaml
provider "aws" {
  region     = "us-east-1" # AWS region
  access_key = ""          # AWS IAM Access key
  secret_key = ""          # AWS IAM Secret key
}

module "red5pro" {
  source = "red5pro/red5pro/aws"
  type   = "standalone"         # Deployment type: standalone, cluster, autoscale
  name   = "red5pro-standalone" # Name to be used on all the resources as identifier

  ubuntu_version        = "22.04"                                 # Ubuntu version for Red5 Pro servers
  path_to_red5pro_build = "./red5pro-server-0.0.0.b0-release.zip" # Absolute path or relative path to Red5 Pro server ZIP file

  # SSH key configuration
  ssh_key_use_existing              = false                                               # Use existing SSH key pair or create a new one. true = use existing, false = create new SSH key pair
  ssh_key_name_existing             = "example_key"                                       # SSH key name existing in AWS
  ssh_key_private_key_path_existing = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/example_key.pem" # SSH private key path existing in local machine

  # VPC configuration
  vpc_use_existing = false       # true - use existing VPC and subnets, false - create new VPC and subnets automatically
  vpc_id_existing  = "vpc-12345" # VPC ID for existing VPC

  # Elastic IP configuration
  standalone_elastic_ip_use_existing = false     # true - use existing elastic IP, false - create new elastic IP automatically
  standalone_elastic_ip_existing     = "1.2.3.4" # Existing Elastic IP

  # Standalone Red5 Pro server HTTPS (SSL) certificate configuration
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

  # Standalone Red5 Pro server EC2 instance configuration
  standalone_instance_type = "t3.medium" # Instance type for Red5 Pro server. Example: t3.medium, c5.large, c5.xlarge, c5.2xlarge, c5.4xlarge
  standalone_volume_size   = 16          # Volume size for Red5 Pro server

  # Red5Pro general configuration
  red5pro_license_key = "1111-2222-3333-4444" # Red5 Pro license key (https://account.red5.net/login)
  red5pro_api_enable  = true                  # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5.net/docs/development/api/overview/)
  red5pro_api_key     = "example_key"         # Red5 Pro server API key (https://www.red5.net/docs/development/api/overview/)

  # Standalone Red5pro Server Configuration
  standalone_red5pro_inspector_enable                    = false                                     # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5.net/docs/troubleshooting/inspector/overview/)
  standalone_red5pro_restreamer_enable                   = false                                     # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5.net/docs/special/restreamer/overview/)
  standalone_red5pro_socialpusher_enable                 = false                                     # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5.net/docs/special/social-media-plugin/overview/)
  standalone_red5pro_suppressor_enable                   = false                                     # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  standalone_red5pro_hls_enable                          = false                                     # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5.net/docs/protocols/hls-plugin/hls-vod/)
  standalone_red5pro_hls_output_format                   = "TS"                                      # HLS output format. Options: TS, FMP4, SMP4
  standalone_red5pro_hls_dvr_playlist                    = "false"                                   # HLS DVR playlist. Options: true, false
  standalone_red5pro_webhooks_enable                     = false                                     # true - enable Red5 Pro server webhooks, false - disable Red5 Pro server webhooks (https://www.red5.net/docs/special/webhooks/overview/)
  standalone_red5pro_webhooks_endpoint                   = "https://example.com/red5/status"         # Red5 Pro server webhooks endpoint
  standalone_red5pro_round_trip_auth_enable              = false                                     # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5.net/docs/special/round-trip-auth/overview/)
  standalone_red5pro_round_trip_auth_host                = "round-trip-auth.example.com"             # Round trip authentication server host
  standalone_red5pro_round_trip_auth_port                = 3000                                      # Round trip authentication server port
  standalone_red5pro_round_trip_auth_protocol            = "http"                                    # Round trip authentication server protocol
  standalone_red5pro_round_trip_auth_endpoint_validate   = "/validateCredentials"                    # Round trip authentication server endpoint for validate
  standalone_red5pro_round_trip_auth_endpoint_invalidate = "/invalidateCredentials"                  # Round trip authentication server endpoint for invalidate
  standalone_red5pro_cloudstorage_enable                 = false                                     # true - enable Red5 Pro server cloud storage, false - disable Red5 Pro server cloud storage (https://www.red5.net/docs/special/cloudstorage-plugin/aws-s3-cloud-storage/)
  standalone_red5pro_cloudstorage_aws_access_key         = ""                                        # AWS access key for Red5 Pro cloud storage (S3 Bucket)
  standalone_red5pro_cloudstorage_aws_secret_key         = ""                                        # AWS secret key for Red5 Pro cloud storage (S3 Bucket)
  standalone_red5pro_cloudstorage_aws_bucket_name        = "s3-bucket-example-name"                  # AWS bucket name for Red5 Pro cloud storage (S3 Bucket)
  standalone_red5pro_cloudstorage_aws_region             = "us-east-1"                               # AWS region for Red5 Pro cloud storage  (S3 Bucket)
  standalone_red5pro_cloudstorage_postprocessor_enable   = false                                     # true - enable Red5 Pro server postprocessor, false - disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)
  standalone_red5pro_cloudstorage_aws_bucket_acl_policy  = "public-read"                             # AWS bucket ACL policy for Red5 Pro cloud storage (S3 Bucket) Example: none, public-read, authenticated-read, private, public-read-write
  standalone_red5pro_stream_auto_record_enable           = false                                     # true - enable Red5 Pro server broadcast stream auto record, false - disable Red5 Pro server broadcast stream auto record
  standalone_red5pro_coturn_enable                       = false                                     # true - enable customized Coturn configuration for Red5Pro server, false - disable customized Coturn configuration for Red5Pro server (https://www.red5.net/docs/installation/turn-stun/turnstun/)
  standalone_red5pro_coturn_address                      = "stun:1.2.3.4:3478"                       # Customized coturn address for Red5Pro server (https://www.red5.net/docs/installation/turn-stun/turnstun/)
  standalone_red5pro_efs_enable                          = false                                     # enable/disable EFS mount to record streams
  standalone_red5pro_efs_dns_name                        = "example.efs.region.amazonaws.com"        # EFS DNS name
  standalone_red5pro_efs_mount_point                     = "/usr/local/red5pro/webapps/live/streams" # EFS mount point
  standalone_red5pro_brew_mixer_enable                   = false                                     # true - enable Red5 Pro server brew mixer, false - disable Red5 Pro server brew mixer

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

### Stream Manager 2.0 cluster with autoscaling nodes (cluster) - [Example](https://github.com/red5pro/terraform-aws-red5pro/tree/master/examples/cluster)

In the following example, Terraform module will automates the infrastructure provisioning of the Stream Manager 2.0 cluster with Red5 Pro (SM2.0) Autoscaling node group (origins, edges, transcoders, relays)

#### Terraform Deployed Resources (cluster)

- VPC
- Public subnet
- Internet getaway
- Route table
- Security list
    - Security group for Stream Manager 2.0
    - Security group for Kafka
    - Security group for Red5 Pro (SM2.0) Autoscaling nodes
- SSH key pair (use existing or create a new one)
- Standalone Kafka instance (optional).
- Stream Manager 2.0 instance. Optionally include a Kafka server on the same instance.
- SSL certificate for Stream Manager 2.0 instance. Options:
  - `none` - Stream Manager 2.0 without HTTPS and SSL certificate. Only HTTP on port `80`
  - `letsencrypt` - Stream Manager 2.0 with HTTPS and SSL certificate obtained by Let's Encrypt. HTTP on port `80`, HTTPS on port `443`
  - `imported` - Stream Manager 2.0 with HTTPS and imported SSL certificate. HTTP on port `80`, HTTPS on port `443`
- Red5 Pro (SM2.0) node instance image (origins, edges, transcoders, relays)
- Red5 Pro (SM2.0) Autoscaling node group (origins, edges, transcoders, relays)
  
> Note: For cluster deployments, this module also deploys an AWS IAM Role and IAM Policy that are attached to the Stream Manager EC2 instance via an instance profile. This enables the Stream Manager to authenticate to AWS (without static keys) and run Terraform operations as needed.

#### Example main.tf (cluster)

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

### Autoscaling Stream Managers 2.0 with autoscaling nodes (autoscale) - [Example](https://github.com/red5pro/terraform-aws-red5pro/tree/master/examples/autoscale)

In the following example, Terraform module will automates the infrastructure provisioning of the Autoscale Stream Managers 2.0 with Red5 Pro (SM2.0) Autoscaling node group (origins, edges, transcoders, relays)

#### Terraform Deployed Resources (autoscale)

- VPC
- Public subnet
- Internet getaway
- Route table
- Security list
    - Security group for Stream Manager 2.0
    - Security group for Kafka
    - Security group for Red5 Pro (SM2.0) Autoscaling nodes
- SSH key pair (use existing or create a new one)
- Standalone Kafka instance
- Stream Manager 2.0 instance image
- Instance poll for Stream Manager 2.0 instances
- Autoscaling configuration for Stream Manager 2.0 instances
- Application Load Balancer for Stream Manager 2.0 instances.
- SSL certificate for Application Load Balancer. Options:
  - `none` - Load Balancer without HTTPS and SSL certificate. Only HTTP on port `80`
  - `imported` - Load Balancer with HTTPS and imported SSL certificate to the AWS Certificate Manager. HTTP on port `80`, HTTPS on port `443`
  - `existing` - Load Balancer with HTTPS and existing SSL certificate in the AWS Certificate Manager. HTTP on port `80`, HTTPS on port `443`
- Red5 Pro (SM2.0) node instance image (origins, edges, transcoders, relays)
- Red5 Pro (SM2.0) Autoscaling node group (origins, edges, transcoders, relays)
  
> Note: For autoscale deployments, this module also deploys an AWS IAM Role and IAM Policy. The role is attached to the initial Stream Manager instance and included in the Launch Template for autoscaled Stream Managers via an instance profile. This allows Terraform operations to run using IAM role credentials inside the Stream Manager containers, eliminating static access keys.

#### Example main.tf (autoscale)

```yaml
provider "aws" {
  region = "us-east-1" # AWS region
}

module "red5pro" {
  source                = "../../"
  type                  = "autoscale"                             # Deployment type: standalone, cluster, autoscale
  name                  = "red5pro-auto"                          # Name to be used on all the resources as identifier
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
  kafka_standalone_instance_type = "m5.xlarge" # Instance type for Kafka standalone instance
  kafka_standalone_volume_size   = 16          # Volume size in GB for Kafka standalone instance

  # Stream Manager configuration 
  stream_manager_instance_type                = "m5.xlarge"                # Instance type for Stream Manager
  stream_manager_volume_size                  = 16                         # Volume size for Stream Manager
  stream_manager_autoscaling_desired_capacity = 1                          # Desired capacity for Stream Manager autoscaling group
  stream_manager_autoscaling_minimum_capacity = 1                          # Minimum capacity for Stream Manager autoscaling group
  stream_manager_autoscaling_maximum_capacity = 2                          # Maximum capacity for Stream Manager autoscaling group
  stream_manager_auth_user                    = "example_user"             # Stream Manager 2.0 authentication user name
  stream_manager_auth_password                = "example_password"         # Stream Manager 2.0 authentication password
  stream_manager_proxy_user                   = "example_proxy_user"       # Stream Manager 2.0 proxy user name
  stream_manager_proxy_password               = "example_proxy_password"   # Stream Manager 2.0 proxy password
  stream_manager_spatial_user                 = "example_spatial_user"     # Stream Manager 2.0 spatial user name
  stream_manager_spatial_password             = "example_spatial_password" # Stream Manager 2.0 spatial password
  stream_manager_version                      = "latest"                   # Stream Manager 2.0 docker images version (latest, 14.1.0, 14.1.1, etc.) - https://hub.docker.com/r/red5pro/as-admin/tags

  # Stream Manager 2.0 Load Balancer HTTPS (SSL) certificate configuration
  https_ssl_certificate = "none" # none - do not use HTTPS/SSL certificate, imported - import existing HTTPS/SSL certificate

  # Example of imported HTTPS/SSL certificate configuration - please uncomment and provide your domain name, certificate and key paths
  # https_ssl_certificate                = "imported"            # Improt local HTTPS/SSL certificate to AWS ACM
  # https_ssl_certificate_domain_name    = "red5pro.example.com" # Replace with your domain name
  # https_ssl_certificate_cert_path      = "./cert.pem"          # Path to cert file
  # https_ssl_certificate_key_path       = "./privkey.pem"       # Path to privkey file
  # https_ssl_certificate_fullchain_path = "./fullchain.pem"     # Path to full chain file

  # Example of existing HTTPS/SSL certificate configuration - please uncomment and provide your domain name
  # https_ssl_certificate             = "existing"             # Use existing HTTPS/SSL certificate from AWS ACM
  # https_ssl_certificate_domain_name = "red5pro.example.com"  # Replace with your domain name

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

> - WebRTC broadcast does not work in WEB browsers without an HTTPS (SSL) certificate.
> - To activate HTTPS/SSL, you need to add a DNS A record for the public IP address of your Red5 Pro server or Stream Manager 2.0.
