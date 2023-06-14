variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}
variable "type" {
  description = "Type of deployment: single, cluster, autoscaling"
  type        = string
  default     = ""
  validation {
    condition     = var.type == "single" || var.type == "cluster" || var.type == "autoscaling"
    error_message = "The type value must be a valid! Example: single, cluster, autoscaling"
  }
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
  description = "SSH key pair name existing"
  type        = string
  default     = "red5pro_ssh_key"
}

variable "ssh_private_key_path" {
  description = "SSH private key path existing"
  type        = string
  default     = "/home/ubuntu/.ssh/red5pro_ssh_key.pem"
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
  default     = "vpc-000"
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
  default     = "sg-000"
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
  default     = "10.10.10.10"
}

# Red5 Pro single server configuration
variable "single_instance_type" {
  description = "Red5 Pro Single server instance type"
  type        = string
  default     = "t2.medium"
}
variable "single_volume_size" {
  description = "Red5 Pro Single server volume size"
  type        = number
  default     = 8
}
variable "red5pro_inspector_enable" {
  description = "Red5 Pro Single server Inspector enable"
  type        = bool
  default     = false
}
variable "red5pro_restreamer_enable" {
  description = "Red5 Pro Single server Restreamer enable"
  type        = bool
  default     = false
}
variable "red5pro_socialpusher_enable" {
  description = "Red5 Pro Single server SocialPusher enable"
  type        = bool
  default     = false
}
variable "red5pro_suppressor_enable" {
  description = "Red5 Pro Single server Suppressor enable"
  type        = bool
  default     = false
}
variable "red5pro_hls_enable" {
  description = "Red5 Pro Single server HLS enable"
  type        = bool
  default     = false
}
variable "red5pro_round_trip_auth_enable" {
  description = "value to set the round trip auth for origin node"
  type        = bool
  default     = false
}
variable "red5pro_round_trip_auth_host" {
  description = "value to set the round trip auth host for origin node"
  type        = string
  default     = ""
}
variable "red5pro_round_trip_auth_port" {
  description = "value to set the round trip auth port for origin node"
  type        = number
  default     = 0
}
variable "red5pro_round_trip_auth_protocol" {
  description = "value to set the round trip auth protocol for origin node"
  type        = string
  default     = ""
}
variable "red5pro_round_trip_auth_endpoint_validate" {
  description = "value to set the round trip auth endpoint valid for origin node"
  type        = string
  default     = ""
}
variable "red5pro_round_trip_auth_endpoint_invalidate" {
  description = "value to set the round trip auth endpoint invalid for origin node"
  type        = string
  default     = ""
}


# MySQL configuration
variable "mysql_rds_create" {
  description = "Create a new MySQL instance"
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
  default     = "smadmin"
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
  description = "Enable HTTPS and get SSL certificate using Let's Encrypt automaticaly (single/cluster)"
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
  default     = "terraform@infrared5.com"
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
  default     = "t2.medium"
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

variable "stream_manager_create" {
  description = "Create a new Stream Manager instance"
  type        = bool
  default     = true
}

variable "stream_manager_autoscaling" {
  description = "value to enable autoscaling for stream manager"
  type        = bool
  default     = false
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
variable "red5pro_license_key" {
  description = "Red5 Pro license key"
  type        = string
  default     = ""
}
variable "red5pro_cluster_key" {
  description = "Red5 Pro node cluster key"
  type        = string
  default     = ""
}
variable "red5pro_api_enable" {
  description = "Red5 Pro Single server API enable"
  type        = bool
  default     = true
}
variable "red5pro_api_key" {
  description = "Red5 Pro Single server API key"
  type        = string
  default     = ""
}

variable "origin_image_create" {
  description = "value to set the origin node image"
  type        = bool
  default     = true
}
variable "origin_image_instance_type" {
  description = "value to set the instance type for origin node"
  type        = string
  default     = "t2.medium"
}
variable "origin_image_volume_size" {
  description = "value to set the volume size for origin node"
  type        = number
  default     = 8
}
variable "origin_image_red5pro_inspector_enable" {
  description = "value to set the inspector for origin node"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_restreamer_enable" {
  description = "value to set the restreamer for origin node"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_socialpusher_enable" {
  description = "value to set the socialpusher for origin node"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_suppressor_enable" {
  description = "value to set the suppressor for origin node"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_hls_enable" {
  description = "value to set the hls for origin node"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_round_trip_auth_enable" {
  description = "value to set the round trip auth for origin node"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_round_trip_auth_host" {
  description = "value to set the round trip auth host for origin node"
  type        = string
  default     = ""
}
variable "origin_image_red5pro_round_trip_auth_port" {
  description = "value to set the round trip auth port for origin node"
  type        = number
  default     = 0
}
variable "origin_image_red5pro_round_trip_auth_protocol" {
  description = "value to set the round trip auth protocol for origin node"
  type        = string
  default     = ""
}
variable "origin_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "value to set the round trip auth endpoint valid for origin node"
  type        = string
  default     = ""
}
variable "origin_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "value to set the round trip auth endpoint invalid for origin node"
  type        = string
  default     = ""
}

variable "edge_image_create" {
  description = "value to set the edge node image"
  type        = bool
  default     = false
}
variable "edge_image_instance_type" {
  description = "value to set the instance type for edge node"
  type        = string
  default     = "t2.medium"
}
variable "edge_image_volume_size" {
  description = "value to set the volume size for edge node"
  type        = number
  default     = 8
}
variable "edge_image_red5pro_inspector_enable" {
  description = "value to set the inspector for edge node"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_restreamer_enable" {
  description = "value to set the restreamer for edge node"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_socialpusher_enable" {
  description = "value to set the socialpusher for edge node"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_suppressor_enable" {
  description = "value to set the suppressor for edge node"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_hls_enable" {
  description = "value to set the hls for edge node"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_round_trip_auth_enable" {
  description = "value to set the round trip auth for edge node"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_round_trip_auth_host" {
  description = "value to set the round trip auth host for edge node"
  type        = string
  default     = "10.10.10.10"
}
variable "edge_image_red5pro_round_trip_auth_port" {
  description = "value to set the round trip auth port for edge node"
  type        = number
  default     = 3000
}
variable "edge_image_red5pro_round_trip_auth_protocol" {
  description = "value to set the round trip auth protocol for edge node"
  type        = string
  default     = "http"
}
variable "edge_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "value to set the round trip auth endpoint valid for edge node"
  type        = string
  default     = "/validateCredentials"
}
variable "edge_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "value to set the round trip auth endpoint invalid for edge node"
  type        = string
  default     = "/invalidateCredentials"
}

variable "transcoder_image_create" {
  description = "Create transcoder node image - true or false"
  type        = bool
  default     = false
}
variable "transcoder_image_instance_type" {
  description = "value to set the instance type for transcoder node"
  type        = string
  default     = "t2.medium"
}
variable "transcoder_image_volume_size" {
  description = "value to set the volume size for transcoder node"
  type        = number
  default     = 8
}
variable "transcoder_image_red5pro_inspector_enable" {
  description = "value to set the inspector for transcoder node"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_restreamer_enable" {
  description = "value to set the restreamer for transcoder node"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_socialpusher_enable" {
  description = "value to set the socialpusher for transcoder node"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_suppressor_enable" {
  description = "value to set the suppressor for transcoder node"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_hls_enable" {
  description = "value to set the hls for transcoder node"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_round_trip_auth_enable" {
  description = "value to set the round trip auth for transcoder node"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_round_trip_auth_host" {
  description = "value to set the round trip auth host for transcoder node"
  type        = string
  default     = "10.10.10.10"
}
variable "transcoder_image_red5pro_round_trip_auth_port" {
  description = "value to set the round trip auth port for transcoder node"
  type        = number
  default     = 3000
}
variable "transcoder_image_red5pro_round_trip_auth_protocol" {
  description = "value to set the round trip auth protocol for transcoder node"
  type        = string
  default     = "http"
}
variable "transcoder_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "value to set the round trip auth endpoint valid for transcoder node"
  type        = string
  default     = "/validateCredentials"
}
variable "transcoder_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "value to set the round trip auth endpoint invalid for transcoder node"
  type        = string
  default     = "/invalidateCredentials"
}

variable "relay_image_create" {
  description = "Create relay node image - true or false"
  type        = bool
  default     = false
}
variable "relay_image_instance_type" {
  description = "value to set the instance type for relay node"
  type        = string
  default     = "t2.medium"
}
variable "relay_image_volume_size" {
  description = "value to set the volume size for relay node"
  type        = number
  default     = 8
}
variable "relay_image_red5pro_inspector_enable" {
  description = "value to set the inspector for relay node"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_restreamer_enable" {
  description = "value to set the restreamer for relay node"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_socialpusher_enable" {
  description = "value to set the socialpusher for relay node"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_suppressor_enable" {
  description = "value to set the suppressor for relay node"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_hls_enable" {
  description = "value to set the hls for relay node"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_round_trip_auth_enable" {
  description = "value to set the round trip auth for relay node"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_round_trip_auth_host" {
  description = "value to set the round trip auth host for relay node"
  type        = string
  default     = "10.10.10.10"
}
variable "relay_image_red5pro_round_trip_auth_port" {
  description = "value to set the round trip auth port for relay node"
  type        = number
  default     = 3000
}
variable "relay_image_red5pro_round_trip_auth_protocol" {
  description = "value to set the round trip auth protocol for relay node"
  type        = string
  default     = "http"
}
variable "relay_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "value to set the round trip auth endpoint valid for relay node"
  type        = string
  default     = "/validateCredentials"
}
variable "relay_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "value to set the round trip auth endpoint invalid for relay node"
  type        = string
  default     = "/invalidateCredentials"
}


variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = ["10.5.0.0/22", "10.5.4.0/22", "10.5.8.0/22", "10.5.12.0/22", "10.5.16.0/22"]
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

variable "security_group_mysql_ingress" {
  description = "Security group for MySQL - ingress"
  type        = list(map(string))
  default = [
    {
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = "::/0"
    },
  ]
}

variable "security_group_mysql_egress" {
  description = "Security group for MySQL - egress"
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