variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
  validation {
    condition     = length(var.name) > 0
    error_message = "The name value must be a valid! Example: example-name"
  }
}
variable "type" {
  description = "Type of deployment: single, cluster, autoscaling"
  type        = string
  default     = ""
  validation {
    condition     = var.type == "single" || var.type == "cluster" || var.type == "autoscaling" || var.type == "vpc"
    error_message = "The type value must be a valid! Example: single, cluster, autoscaling"
  }
}
variable "path_to_red5pro_build" {
  description = "Path to the Red5 Pro build zip file, absolute path or relative path. https://account.red5.net/downloads. Example: /home/ubuntu/terraform-aws-red5pro/red5pro-server-0.0.0.b0-release.zip"
  type        = string
  default     = ""
  validation {
    condition     = fileexists(var.path_to_red5pro_build) == true
    error_message = "The path_to_red5pro_build value must be a valid! Example: /home/ubuntu/terraform-aws-red5pro/red5pro-server-0.0.0.b0-release.zip"
  }
}
variable "path_to_aws_cloud_controller" {
  description = "Path to the AWS Cloud Controller jar file, absolute path or relative path. https://account.red5.net/downloads. Example: /home/ubuntu/terraform-aws-red5pro/aws-cloud-controller-0.0.0.jar"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region to deploy the resources"
  default     = ""
}
variable "aws_access_key" {
  description = "AWS access key"
  default     = ""
}
variable "aws_secret_key" {
  description = "AWS secret key"
  default     = ""
}

# SSH key configuration
variable "ssh_key_create" {
  description = "Create a new SSH key pair or use an existing one. true = create new, false = use existing"
  type        = bool
  default     = true
}
variable "ssh_key_name" {
  description = "SSH key pair name new/existing"
  type        = string
  default     = ""
}

variable "ssh_private_key_path" {
  description = "SSH private key path existing"
  type        = string
  default     = ""
}

# VPC configuration
variable "vpc_create" {
  description = "Create a new VPC or use an existing one. true = create new, false = use existing"
  type        = bool
  default     = true
}
variable "vpc_id_existing" {
  description = "VPC ID, this VPC should have minimum 2 public subnets."
  type        = string
  default     = "vpc-12345"
  validation {
    condition     = length(var.vpc_id_existing) > 4 && substr(var.vpc_id_existing, 0, 4) == "vpc-"
    error_message = "The vpc_id_existing value must be a valid! Example: vpc-12345"
  }
}

# Security group configuration
variable "security_group_create" {
  description = "Create a new Security group or use an existing one. true = create new, false = use existing"
  type        = bool
  default     = false
}
variable "security_group_id_existing" {
  description = "Security group ID, this Security group should have open default Red5Pro ports: TCP:443,5080,80,1935,8554, UDP:40000-65535"
  type        = string
  default     = "sg-12345"
  validation {
    condition     = length(var.security_group_id_existing) > 4 && substr(var.security_group_id_existing, 0, 3) == "sg-"
    error_message = "The security_group_id_existing value must be a valid! Example: sg-12345"
  }
}

# Elastic IP configuration
variable "elastic_ip_create" {
  description = "Create a new Elastic IP or use an existing one. true = create new, false = use existing"
  type        = bool
  default     = true
}
variable "elastic_ip_existing" { 
  description = "Elastic IP Existing"
  type        = string
  default     = "1.2.3.4"
}

# Red5 Pro single server configuration
variable "single_instance_type" {
  description = "Red5 Pro Single server instance type"
  type        = string
  default     = "t3.medium"
}
variable "single_volume_size" {
  description = "Red5 Pro Single server volume size"
  type        = number
  default     = 8
}
variable "red5pro_inspector_enable" {
  description = "Red5 Pro Single server Inspector enable/disable (https://www.red5.net/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "red5pro_restreamer_enable" {
  description = "Red5 Pro Single server Restreamer enable/disable (https://www.red5.net/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "red5pro_socialpusher_enable" {
  description = "Red5 Pro Single server SocialPusher enable/disable (https://www.red5.net/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "red5pro_suppressor_enable" {
  description = "Red5 Pro Single server Suppressor enable"
  type        = bool
  default     = false
}
variable "red5pro_hls_enable" {
  description = "Red5 Pro Single server HLS enable/disable (https://www.red5.net/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "red5pro_webhooks_enable" {
  description = "Red5 Pro Single server Webhooks enable/disable (https://www.red5.net/docs/special/webhooks/overview/)"
  type        = bool
  default     = false
}
variable "red5pro_webhooks_endpoint" {
  description = "Red5 Pro Single server Webhooks endpoint"
  type        = string
  default     = ""
}
variable "red5pro_round_trip_auth_enable" {
  description = "Round trip authentication on the red5pro server enable/disable - Auth server should be deployed separately (https://www.red5.net/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "red5pro_round_trip_auth_host" {
  description = "Round trip authentication server host"
  type        = string
  default     = ""
}
variable "red5pro_round_trip_auth_port" {
  description = "Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "red5pro_round_trip_auth_protocol" {
  description = "Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "red5pro_round_trip_auth_endpoint_validate" {
  description = "Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}
variable "red5pro_cloudstorage_enable" {
  description = "Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/aws-s3-cloud-storage/)"
  type        = bool
  default     = false
}
variable "red5pro_cloudstorage_aws_access_key" {
  description = "Red5 Pro server cloud storage - AWS access key (S3 Bucket)"
  type        = string
  default     = ""
}
variable "red5pro_cloudstorage_aws_secret_key" {
  description = "Red5 Pro server cloud storage - AWS secret key (S3 Bucket)"
  type        = string
  default     = ""
}
variable "red5pro_cloudstorage_aws_bucket_name" {
  description = "Red5 Pro server cloud storage - AWS bucket name (S3 Bucket)"
  type        = string
  default     = ""
}
variable "red5pro_cloudstorage_aws_region" {
  description = "Red5 Pro server cloud storage - AWS region (S3 Bucket)"
  type        = string
  default     = ""
}
variable "red5pro_cloudstorage_postprocessor_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}
variable "red5pro_cloudstorage_aws_bucket_acl_policy" {
  description = "Red5 Pro server cloud storage - AWS bucket ACL policy (S3 Bucket). Example: none, public-read, authenticated-read, private, public-read-write"
  type        = string
  default     = "public-read"
}
variable "red5pro_coturn_enable" {
  description = "Red5Pro server customized Coturn configuration"
  type        = bool
  default     = false
}
variable "red5pro_coturn_address" {
  description = "Red5Pro server customized Coturn address. Example: stun:1.2.3.4:3478"
  type        = string
  default     = ""
}
variable "red5pro_efs_enable" {
  description = "Red5 Pro server enable/disable EFS mount to record streams"
  type        = bool
  default     = false
}
variable "red5pro_efs_dns_name" {
  description = "Red5 Pro server EFS DNS name"
  type        = string
  default     = ""
}
variable "red5pro_efs_mount_point" {
  description = "Red5 Pro server EFS mount point"
  type        = string
  default     = "/usr/local/red5pro/webapps/live/streams"
}

# MySQL configuration
variable "mysql_rds_create" {
  description = "Create a new RDS MySQL instance"
  type        = bool
  default     = false
}
variable "mysql_rds_instance_type" {
  description = "MySQL instance type"
  type        = string
  default     = "db.t2.micro"
}
variable "mysql_user_name" {
  description = "MySQL user name"
  type        = string
  default     = ""
}
variable "mysql_password" {
  description = "MySQL password"
  type        = string
  default     = ""
}
variable "mysql_port" {
  description = "MySQL port"
  type        = number
  default     = 3306
}
# HTTPS/SSL variables for single/cluster
variable "https_letsencrypt_enable" {
  description = "Enable HTTPS and get SSL certificate using Let's Encrypt automaticaly (single/cluster) (https://www.red5.net/docs/installation/ssl/overview/)"
  type        = bool
  default     = false
}
variable "https_letsencrypt_certificate_domain_name" {
  description = "Domain name for Let's Encrypt ssl certificate (single/cluster)"
  type        = string
  default     = ""
}
variable "https_letsencrypt_certificate_email" {
  description = "Email for Let's Encrypt ssl certificate (single/cluster)"
  type        = string
  default     = "email@example.com"
}
variable "https_letsencrypt_certificate_password" {
  description = "Password for Let's Encrypt ssl certificate (single/cluster)"
  type        = string
  default     = ""
}
# HTTPS/SSL variables for autoscaling
variable "https_certificate_manager_use_existing" {
  description = "Use existing AWS Certificate Manager certificate (autoscaling)"
  type        = bool
  default     = false
}
variable "https_certificate_manager_certificate_name" {
  description = "AWS Certificate Manager certificate name (autoscaling)"
  type        = string
  default     = ""
}

variable "stream_manager_instance_type" {
  description = "value to set the instance type for stream manager"
  type        = string
  default     = "t3.medium"
}
variable "stream_manager_volume_size" {
  description = "value to set the volume size for stream manager"
  type        = number
  default     = 16
}
variable "stream_manager_api_key" {
  description = "value to set the api key for stream manager"
  type        = string
  default     = ""
}
variable "stream_manager_autoscaling_desired_capacity" {
  description = "value to set the desired capacity for stream manager autoscaling"
  type        = number
  default     = 1
}
variable "stream_manager_autoscaling_minimum_capacity" {
  description = "value to set the minimum capacity for stream manager autoscaling"
  type        = number
  default     = 1
}
variable "stream_manager_autoscaling_maximum_capacity" {
  description = "value to set the maximum capacity for stream manager autoscaling"
  type        = number
  default     = 1
}
variable "stream_manager_coturn_enable" {
  description = "Red5Pro Stream Manager customized Coturn configuration"
  type        = bool
  default     = false
}
variable "stream_manager_coturn_address" {
  description = "Red5Pro Stream Manager customized Coturn address. Example: stun:1.2.3.4:3478"
  type        = string
  default     = ""
}
variable "red5pro_license_key" {
  description = "Red5 Pro license key (https://www.red5.net/docs/installation/installation/license-key/)"
  type        = string
  default     = ""
}
variable "red5pro_cluster_key" {
  description = "Red5 Pro node cluster key"
  type        = string
  default     = ""
}
variable "red5pro_api_enable" {
  description = "Red5 Pro Server API enable/disable (https://www.red5.net/docs/development/api/overview/)"
  type        = bool
  default     = true
}
variable "red5pro_api_key" {
  description = "Red5 Pro Single server API key"
  type        = string
  default     = ""
}

# Red5 Pro Origin node image configuration
variable "origin_image_create" {
  description = "Create new Origin node image true/false. (Default:true) (https://www.red5.net/docs/special/relays/overview/#origin-and-edge-nodes)"
  type        = bool
  default     = false
}
variable "origin_image_instance_type" {
  description = "Origin node image - instance type"
  type        = string
  default     = "t3.medium"
}
variable "origin_image_volume_size" {
  description = "Origin node image - volume size"
  type        = number
  default     = 8
}
variable "origin_image_red5pro_inspector_enable" {
  description = "Origin node image - Inspector enable/disable (https://www.red5.net/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_restreamer_enable" {
  description = "Origin node image - Restreamer enable/disable (https://www.red5.net/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_socialpusher_enable" {
  description = "Origin node image - SocialPusher enable/disable (https://www.red5.net/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_suppressor_enable" {
  description = "Origin node image - Suppressor enable/disable"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_hls_enable" {
  description = "Origin node image - HLS enable/disable (https://www.red5.net/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
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
variable "origin_image_red5pro_round_trip_auth_enable" {
  description = "Origin node image - Round trip authentication on the enable/disable - Auth server should be deployed separately (https://www.red5.net/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_round_trip_auth_host" {
  description = "Origin node image - Round trip authentication server host"
  type        = string
  default     = ""
}
variable "origin_image_red5pro_round_trip_auth_port" {
  description = "Origin node image - Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "origin_image_red5pro_round_trip_auth_protocol" {
  description = "Origin node image - Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "origin_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "Origin node image - Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "origin_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Origin node image - Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}
variable "origin_image_red5pro_cloudstorage_enable" {
  description = "Origin node image - enable/disable Red5 Pro server cloud storage (https://www.red5.net/docs/special/cloudstorage-plugin/aws-s3-cloud-storage/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_cloudstorage_aws_access_key" {
  description = "Origin node image - AWS access key for cloud storage (S3 Bucket)"
  type        = string
  default     = ""
}
variable "origin_image_red5pro_cloudstorage_aws_secret_key" {
  description = "Origin node image - AWS secret key for cloud storage (S3 Bucket)"
  type        = string
  default     = ""
}
variable "origin_image_red5pro_cloudstorage_aws_bucket_name" {
  description = "Origin node image - AWS bucket name for cloud storage (S3 Bucket)"
  type        = string
  default     = ""
}
variable "origin_image_red5pro_cloudstorage_aws_region" {
  description = "Origin node image - AWS region for cloud storage (S3 Bucket)"
  type        = string
  default     = ""
}
variable "origin_image_red5pro_cloudstorage_postprocessor_enable" {
  description = "Origin node image - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_cloudstorage_aws_bucket_acl_policy" {
  description = "Origin node image - AWS bucket ACL policy for cloud storage (S3 Bucket). Example: none, public-read, authenticated-read, private, public-read-write"
  type        = string
  default     = "public-read"
}
variable "origin_image_red5pro_efs_enable" {
  description = "Origin node image enable/disable EFS mount to record streams"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_efs_dns_name" {
  description = "Origin node image - EFS DNS name"
  type        = string
  default     = ""
}
variable "origin_image_red5pro_efs_mount_point" {
  description = "Origin node image - EFS mount point"
  type        = string
  default     = "/usr/local/red5pro/webapps/live/streams"
}

# Red5 Pro Edge node image configuration
variable "edge_image_create" {
  description = "Create new Edge node image true/false. (Default:true) (https://www.red5.net/docs/special/relays/overview/#origin-and-edge-nodes)"
  type        = bool
  default     = false
}
variable "edge_image_instance_type" {
  description = "Edge node image - instance type"
  type        = string
  default     = "t3.medium"
}
variable "edge_image_volume_size" {
  description = "Edge node image - volume size"
  type        = number
  default     = 8
}
variable "edge_image_red5pro_inspector_enable" {
  description = "Edge node image - Inspector enable/disable (https://www.red5.net/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_restreamer_enable" {
  description = "Edge node image - Restreamer enable/disable (https://www.red5.net/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_socialpusher_enable" {
  description = "Edge node image - SocialPusher enable/disable (https://www.red5.net/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_suppressor_enable" {
  description = "Edge node image - Suppressor enable/disable"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_hls_enable" {
  description = "Edge node image - HLS enable/disable (https://www.red5.net/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_hls_enable" {
  description = "Edge node image - HLS enable/disable (https://www.red5.net/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_webhooks_enable" {
  description = "Edge node image - Webhooks enable/disable (https://www.red5.net/docs/special/webhooks/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_round_trip_auth_enable" {
  description = "Edge node image - Round trip authentication on the enable/disable - Auth server should be deployed separately (https://www.red5.net/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_round_trip_auth_host" {
  description = "Edge node image - Round trip authentication server host"
  type        = string
  default     = ""
}
variable "edge_image_red5pro_round_trip_auth_port" {
  description = "Edge node image - Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "edge_image_red5pro_round_trip_auth_protocol" {
  description = "Edge node image - Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "edge_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "Edge node image - Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "edge_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Edge node image - Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}

# Red5 Pro Transcoder node image configuration
variable "transcoder_image_create" {
  description = "Create new Transcoder node image true/false. (Default:true) (https://www.red5.net/docs/special/relays/overview/#origin-and-edge-nodes)"
  type        = bool
  default     = false
}
variable "transcoder_image_instance_type" {
  description = "Transcoder node image - instance type"
  type        = string
  default     = "t3.medium"
}
variable "transcoder_image_volume_size" {
  description = "Transcoder node image - volume size"
  type        = number
  default     = 8
}
variable "transcoder_image_red5pro_inspector_enable" {
  description = "Transcoder node image - Inspector enable/disable (https://www.red5.net/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_restreamer_enable" {
  description = "Transcoder node image - Restreamer enable/disable (https://www.red5.net/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_socialpusher_enable" {
  description = "Transcoder node image - SocialPusher enable/disable (https://www.red5.net/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_suppressor_enable" {
  description = "Transcoder node image - Suppressor enable/disable"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_hls_enable" {
  description = "Transcoder node image - HLS enable/disable (https://www.red5.net/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_webhooks_enable" {
  description = "Transcoder node image - Webhooks enable/disable (https://www.red5.net/docs/special/webhooks/overview/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_webhooks_endpoint" {
  description = "Transcoder node image - Webhooks endpoint"
  type        = string
  default     = ""
}
variable "transcoder_image_red5pro_round_trip_auth_enable" {
  description = "Transcoder node image - Round trip authentication on the enable/disable - Auth server should be deployed separately (https://www.red5.net/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_round_trip_auth_host" {
  description = "Transcoder node image - Round trip authentication server host"
  type        = string
  default     = ""
}
variable "transcoder_image_red5pro_round_trip_auth_port" {
  description = "Transcoder node image - Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "transcoder_image_red5pro_round_trip_auth_protocol" {
  description = "Transcoder node image - Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "transcoder_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "Transcoder node image - Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "transcoder_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Transcoder node image - Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}
variable "transcoder_image_red5pro_cloudstorage_enable" {
  description = "Transcoder node image - enable/disable Red5 Pro server cloud storage (https://www.red5.net/docs/special/cloudstorage-plugin/aws-s3-cloud-storage/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_cloudstorage_aws_access_key" {
  description = "Transcoder node image - AWS access key for cloud storage (S3 Bucket)"
  type        = string
  default     = ""
}
variable "transcoder_image_red5pro_cloudstorage_aws_secret_key" {
  description = "Transcoder node image - AWS secret key for cloud storage (S3 Bucket)"
  type        = string
  default     = ""
}
variable "transcoder_image_red5pro_cloudstorage_aws_bucket_name" {
  description = "Transcoder node image - AWS bucket name for cloud storage (S3 Bucket)"
  type        = string
  default     = ""
}
variable "transcoder_image_red5pro_cloudstorage_aws_region" {
  description = "Transcoder node image - AWS region for cloud storage (S3 Bucket)"
  type        = string
  default     = ""
}
variable "transcoder_image_red5pro_cloudstorage_postprocessor_enable" {
  description = "Transcoder node image - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_cloudstorage_aws_bucket_acl_policy" {
  description = "Transcoder node image - AWS bucket ACL policy for cloud storage (S3 Bucket). Example: none, public-read, authenticated-read, private, public-read-write"
  type        = string
  default     = "public-read"
}
variable "transcoder_image_red5pro_efs_enable" {
  description = "Transcoder node image enable/disable EFS mount to record streams"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_efs_dns_name" {
  description = "Transcoder node image - EFS DNS name"
  type        = string
  default     = ""
}
variable "transcoder_image_red5pro_efs_mount_point" {
  description = "Transcoder node image - EFS mount point"
  type        = string
  default     = "/usr/local/red5pro/webapps/live/streams"
}

# Red5 Pro Relay node image configuration
variable "relay_image_create" {
  description = "Create new Relay node image true/false. (Default:true) (https://www.red5.net/docs/special/relays/overview/#origin-and-edge-nodes)"
  type        = bool
  default     = false
}
variable "relay_image_instance_type" {
  description = "Relay node image - instance type"
  type        = string
  default     = "t3.medium"
}
variable "relay_image_volume_size" {
  description = "Relay node image - volume size"
  type        = number
  default     = 8
}
variable "relay_image_red5pro_inspector_enable" {
  description = "Relay node image - Inspector enable/disable (https://www.red5.net/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_restreamer_enable" {
  description = "Relay node image - Restreamer enable/disable (https://www.red5.net/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_socialpusher_enable" {
  description = "Relay node image - SocialPusher enable/disable (https://www.red5.net/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_suppressor_enable" {
  description = "Relay node image - Suppressor enable/disable"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_hls_enable" {
  description = "Relay node image - HLS enable/disable (https://www.red5.net/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_round_trip_auth_enable" {
  description = "Relay node image - Round trip authentication on the enable/disable - Auth server should be deployed separately (https://www.red5.net/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_round_trip_auth_host" {
  description = "Relay node image - Round trip authentication server host"
  type        = string
  default     = ""
}
variable "relay_image_red5pro_round_trip_auth_port" {
  description = "Relay node image - Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "relay_image_red5pro_round_trip_auth_protocol" {
  description = "Relay node image - Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "relay_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "Relay node image - Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "relay_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Relay node image - Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.5.0.0/16"
}
variable "vpc_public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = ["10.5.0.0/22", "10.5.4.0/22", "10.5.8.0/22", "10.5.12.0/22", "10.5.16.0/22", "10.5.20.0/22", "10.5.24.0/22", "10.5.28.0/22", "10.5.32.0/22", "10.5.36.0/22", "10.5.40.0/22", "10.5.44.0/22"]
}

variable "security_group_stream_manager_ingress" {
  description = "Security group for Stream Managers - ingress"
  type        = list(map(string))
  default = [
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 5080
      to_port         = 5080
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
  ]
}

variable "security_group_stream_manager_egress" {
  description = "Security group for Stream Managers - egress"
  type        = list(map(string))
  default = [
    {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
  ]
}

variable "security_group_node_ingress" {
  description = "Security group for Node - ingress"
  type        = list(map(string))
  default = [
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 5080
      to_port         = 5080
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 1935
      to_port         = 1935
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 8554
      to_port         = 8554
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 8000
      to_port         = 8001
      protocol        = "udp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 40000
      to_port         = 65535
      protocol        = "udp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
  ]
}

variable "security_group_node_egress" {
  description = "Security group for Node - egress"
  type        = list(map(string))
  default = [
    {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
  ]
}

variable "security_group_single_ingress" {
  description = "Security group for Single Red5Pro server  - ingress"
  type        = list(map(string))
  default = [
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 5080
      to_port         = 5080
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 1935
      to_port         = 1935
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 8554
      to_port         = 8554
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 8000
      to_port         = 8001
      protocol        = "udp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
    {
      from_port       = 40000
      to_port         = 65535
      protocol        = "udp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
  ]
}

variable "security_group_single_egress" {
  description = "Security group for Single Red5Pro server - egress"
  type        = list(map(string))
  default = [
    {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
  ]
}

 # Red5 Pro autoscaling Node group - (Optional) 
variable "node_group_create" {
  description = "Create new node group. Linux or Mac OS only."
  type        = bool
  default     = false
}
variable "node_group_name" {
  description = "Node group name"
  type        = string
  default     = "terraform-node-group"
}
variable "node_group_origins" {
  description = "Number of Origins"
  type        = number
  default     = 0
}
variable "node_group_origins_instance_type" {
  description = "Instance type for Origins"
  type        = string
  default     = "t3.medium"
}
variable "node_group_origins_capacity" {
  description = "Connections capacity for Origins"
  type        = number
  default     = 30
}
variable "node_group_edges" {
  description = "Number of Edges"
  type        = number
  default     = 0
}
variable "node_group_edges_instance_type" {
  description = "Instance type for Edges"
  type        = string
  default     = "t3.medium"
}
variable "node_group_edges_capacity" {
  description = "Connections capacity for Edges"
  type        = number
  default     = 300
}
variable "node_group_transcoders" {
  description = "Number of Transcoders"
  type        = number
  default     = 0
}
variable "node_group_transcoders_instance_type" {
  description = "Instance type for Transcoders"
  type        = string
  default     = "t3.medium"
}
variable "node_group_transcoders_capacity" {
  description = "Connections capacity for Transcoders"
  type        = number
  default     = 30
}
variable "node_group_relays" {
  description = "Number of Relays"
  type        = number
  default     = 0
}
variable "node_group_relays_instance_type" {
  description = "Instance type for Relays"
  type        = string
  default     = "t3.medium"
}
variable "node_group_relays_capacity" {
  description = "Connections capacity for Relays"
  type        = number
  default     = 30
}
variable "ubuntu_version_aws_image" {
  type = map(string)
  default = {
    18.04 = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"
    20.04 = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
    22.04 = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  }
}
variable "ubuntu_version" {
  description = "Ubuntu version"
  type        = string
  default     = "22.04"
}