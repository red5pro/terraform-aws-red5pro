locals {
  standalone                    = var.type == "standalone" ? true : false
  cluster                       = var.type == "cluster" ? true : false
  autoscale                     = var.type == "autoscale" ? true : false
  cluster_or_autoscale          = local.cluster || local.autoscale ? true : false
  vpc                           = var.type == "vpc" ? true : false
  ssh_key_name                  = local.vpc ? null : var.ssh_key_create ? aws_key_pair.red5pro_ssh_key[0].key_name : data.aws_key_pair.ssh_key_pair[0].key_name
  ssh_private_key               = local.vpc ? null : var.ssh_key_create ? tls_private_key.red5pro_ssh_key[0].private_key_pem : file(var.ssh_private_key_path)
  ssh_private_key_path          = local.vpc ? null : var.ssh_key_create ? local_file.red5pro_ssh_key_pem[0].filename : var.ssh_private_key_path
  vpc_id                        = var.vpc_create ? aws_vpc.red5pro_vpc[0].id : var.vpc_id_existing
  vpc_name                      = var.vpc_create ? aws_vpc.red5pro_vpc[0].tags.Name : data.aws_vpc.selected[0].tags.Name
  subnet_ids                    = var.vpc_create ? tolist(aws_subnet.red5pro_subnets[*].id) : data.aws_subnets.all[0].ids
  subnet_name                   = var.vpc_create ? tolist([for subnet in aws_subnet.red5pro_subnets : lookup(subnet.tags, "Name", "Unnamed-Subnet")]) : [for subnet_id in data.aws_subnets.all[0].ids : lookup(data.aws_subnet.all_subnets[subnet_id].tags, "Name", "Unnamed-Subnet")]
  kafka_standalone_instance     = local.autoscale ? true : local.cluster && var.kafka_standalone_instance_create ? true : false
  kafka_ip                      = local.cluster_or_autoscale ? local.kafka_standalone_instance ? aws_instance.red5pro_kafka[0].private_ip : aws_instance.red5pro_sm[0].private_ip : "null"
  kafka_on_sm_replicas          = local.kafka_standalone_instance ? 0 : 1
  kafka_ssl_keystore_key        = local.cluster_or_autoscale ? nonsensitive(join("\\\\n", split("\n", trimspace(tls_private_key.kafka_server_key[0].private_key_pem_pkcs8)))) : "null"
  kafka_ssl_truststore_cert     = local.cluster_or_autoscale ? nonsensitive(join("\\\\n", split("\n", tls_self_signed_cert.ca_cert[0].cert_pem))) : "null"
  kafka_ssl_keystore_cert_chain = local.cluster_or_autoscale ? nonsensitive(join("\\\\n", split("\n", tls_locally_signed_cert.kafka_server_cert[0].cert_pem))) : "null"
  stream_manager_ip             = local.cluster ? var.stream_manager_elastic_ip_create ? aws_eip.elastic_ip_sm[0].public_ip : data.aws_eip.existing_elastic_ip_sm[0].public_ip : local.autoscale ? aws_instance.red5pro_sm[0].public_ip : "null"
  stream_manager_ssl            = local.autoscale ? "none" : var.https_ssl_certificate
  stream_manager_standalone     = local.autoscale ? false : true
  stream_manager_url            = local.stream_manager_ssl != "none" ? "https://${local.stream_manager_ip}" : "http://${local.stream_manager_ip}"
  standalone_elastic_ip         = local.standalone ? var.standalone_elastic_ip_create ? aws_eip.elastic_ip_standalone[0].public_ip : data.aws_eip.existing_elastic_ip_standalone[0].public_ip : "null"
}

################################################################################
# Elastic IP for Standalone Red5 Pro server
################################################################################

# Create a new Elastic IP (only if standalone_elastic_ip_create = true)
resource "aws_eip" "elastic_ip_standalone" {
  count = local.standalone && var.standalone_elastic_ip_create ? 1 : 0
  tags  = merge({ "Name" = "${var.name}-elastic-ip-standalone" }, var.tags, )
}

# Use an existing Elastic IP (only if standalone_elastic_ip_create = false)
data "aws_eip" "existing_elastic_ip_standalone" {
  count     = local.standalone && var.standalone_elastic_ip_create == false ? 1 : 0
  public_ip = var.standalone_elastic_ip_existing
}

# Associate the EIP with the Stream Manager EC2 instance
resource "aws_eip_association" "elastic_ip_association_standalone" {
  count         = local.standalone ? 1 : 0
  instance_id   = aws_instance.red5pro_standalone[0].id
  allocation_id = var.standalone_elastic_ip_create ? aws_eip.elastic_ip_standalone[0].id : data.aws_eip.existing_elastic_ip_standalone[0].id
}

################################################################################
# Elastic IP for Stream Manager 2.0
################################################################################

# Create a new Elastic IP (only if stream_manager_elastic_ip_create = true)
resource "aws_eip" "elastic_ip_sm" {
  count = local.cluster && var.stream_manager_elastic_ip_create ? 1 : 0
  tags  = merge({ "Name" = "${var.name}-elastic-ip-sm" }, var.tags, )
}

# Use an existing Elastic IP (only if stream_manager_elastic_ip_create = false)
data "aws_eip" "existing_elastic_ip_sm" {
  count     = local.cluster && var.stream_manager_elastic_ip_create == false ? 1 : 0
  public_ip = var.stream_manager_elastic_ip_existing
}

# Associate the EIP with the Stream Manager EC2 instance
resource "aws_eip_association" "elastic_ip_association_sm" {
  count         = local.cluster ? 1 : 0
  instance_id   = aws_instance.red5pro_sm[0].id
  allocation_id = var.stream_manager_elastic_ip_create ? aws_eip.elastic_ip_sm[0].id : data.aws_eip.existing_elastic_ip_sm[0].id
}

################################################################################
# SSH_KEY
################################################################################

# SSH key pair generation
resource "tls_private_key" "red5pro_ssh_key" {
  count     = local.vpc ? 0 : var.ssh_key_create ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Import SSH key pair to AWS
resource "aws_key_pair" "red5pro_ssh_key" {
  count      = local.vpc ? 0 : var.ssh_key_create ? 1 : 0
  key_name   = var.ssh_key_name
  public_key = tls_private_key.red5pro_ssh_key[0].public_key_openssh
}

# Save SSH key pair files to local folder
resource "local_file" "red5pro_ssh_key_pem" {
  count           = local.vpc ? 0 : var.ssh_key_create ? 1 : 0
  filename        = "./${var.ssh_key_name}.pem"
  content         = tls_private_key.red5pro_ssh_key[0].private_key_pem
  file_permission = "0400"
}
resource "local_file" "red5pro_ssh_key_pub" {
  count    = local.vpc ? 0 : var.ssh_key_create ? 1 : 0
  filename = "./${var.ssh_key_name}.pub"
  content  = tls_private_key.red5pro_ssh_key[0].public_key_openssh
}

# Check current SSH key pair on the AWS
data "aws_key_pair" "ssh_key_pair" {
  count    = local.vpc ? 0 : var.ssh_key_create ? 0 : 1
  key_name = var.ssh_key_name
}
################################################################################
# AWS Cloud Infrastructure
################################################################################

# Get information about AWS image ID with Ubuntu
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = [lookup(var.ubuntu_version_aws_image, var.ubuntu_version, "what?")]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

################################################################################
# VPC - Check existing
################################################################################

data "aws_vpc" "selected" {
  count = var.vpc_create ? 0 : 1
  id    = var.vpc_id_existing
  lifecycle {
    postcondition {
      #enable_dns_support   = true
      #enable_dns_hostnames = true
      condition     = self.enable_dns_support == true && self.enable_dns_hostnames == true
      error_message = "ERROR! AWS VPC: ${var.vpc_id_existing} DNS resolution and DNS hostnames need to be enabled. Please check/fix it using AWS console."
    }
  }
}

data "aws_subnets" "all" {
  count = var.vpc_create ? 0 : 1
  filter {
    name   = "vpc-id"
    values = [var.vpc_id_existing]
  }
  lifecycle {
    postcondition {
      condition     = length(self.ids) >= 2
      error_message = "ERROR! AWS VPC: ${var.vpc_id_existing} doesn't have enough subnets. Minimum 2. Please try to use different VPC or create it by terraform."
    }
  }
}

data "aws_subnet" "all_subnets" {
  for_each = var.vpc_create ? toset([]) : toset(data.aws_subnets.all[0].ids)
  id       = each.value
  lifecycle {
    postcondition {
      condition     = self.map_public_ip_on_launch == true
      error_message = "ERROR! Subnet ${self.id} configured without assigning Public IP on launch instances. Please check/fix it using AWS console."
    }
  }
}

################################################################################
# VPC - Create new (VPC + Internet geteway + Subnets + Route table)
################################################################################

data "aws_availability_zones" "available" {
  count = var.vpc_create ? 1 : 0
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }

  lifecycle {
    postcondition {
      condition     = length(self.names) >= 2
      error_message = "ERROR! AWS availability zones less than 2. Please try to use different region."
    }
  }
}

resource "aws_vpc" "red5pro_vpc" {
  count                = var.vpc_create ? 1 : 0
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge({ "Name" = "${var.name}-vpc" }, var.tags, )
}

resource "aws_internet_gateway" "red5pro_igw" {
  count  = var.vpc_create ? 1 : 0
  vpc_id = aws_vpc.red5pro_vpc[0].id

  tags = merge({ "Name" = "${var.name}-igw" }, var.tags, )
}

resource "aws_subnet" "red5pro_subnets" {
  count                   = var.vpc_create ? length(data.aws_availability_zones.available[0].names) : 0
  vpc_id                  = aws_vpc.red5pro_vpc[0].id
  cidr_block              = element(var.vpc_public_subnets, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available[0].names[count.index]

  tags = merge({ "Name" = "${var.name}-subnet-${count.index}" }, var.tags, )
}

resource "aws_route" "red5pro_route" {
  count                  = var.vpc_create ? 1 : 0
  route_table_id         = aws_vpc.red5pro_vpc[0].main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.red5pro_igw[0].id
  depends_on             = [aws_internet_gateway.red5pro_igw[0]]
}

resource "aws_route_table_association" "red5pro_subnets_association" {
  count          = var.vpc_create ? length(aws_subnet.red5pro_subnets) : 0
  subnet_id      = aws_subnet.red5pro_subnets[count.index].id
  route_table_id = aws_vpc.red5pro_vpc[0].main_route_table_id
}

################################################################################
# Security Groups - Create new (Kafka + StreamManager + Nodes)
################################################################################

# Security group for Red5Pro Stream Manager (AWS VPC)
resource "aws_security_group" "red5pro_sm_sg" {
  count       = local.cluster || local.autoscale ? 1 : 0
  name        = "${var.name}-sm-sg"
  description = "Allow inbound/outbound traffic for Stream Manager"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = var.security_group_stream_manager_ingress
    content {
      from_port        = lookup(ingress.value, "from_port", 0)
      to_port          = lookup(ingress.value, "to_port", 0)
      protocol         = lookup(ingress.value, "protocol", "tcp")
      cidr_blocks      = [lookup(ingress.value, "cidr_block", "0.0.0.0/0")]
      ipv6_cidr_blocks = [lookup(ingress.value, "ipv6_cidr_block", "::/0")]
    }
  }
  dynamic "egress" {
    for_each = var.security_group_stream_manager_egress
    content {
      from_port        = lookup(egress.value, "from_port", 0)
      to_port          = lookup(egress.value, "to_port", 0)
      protocol         = lookup(egress.value, "protocol", "-1")
      cidr_blocks      = [lookup(egress.value, "cidr_block", "0.0.0.0/0")]
      ipv6_cidr_blocks = [lookup(egress.value, "ipv6_cidr_block", "::/0")]
    }
  }
  tags = merge({ "Name" = "${var.name}-sm-sg" }, var.tags, )
}

# Security group for Red5Pro Nodes (AWS VPC)
resource "aws_security_group" "red5pro_node_sg" {
  count       = local.cluster || local.autoscale ? 1 : 0
  name        = "${var.name}-node-sg"
  description = "Allow inbound/outbound traffic for Nodes"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = var.security_group_node_ingress
    content {
      from_port        = lookup(ingress.value, "from_port", 0)
      to_port          = lookup(ingress.value, "to_port", 0)
      protocol         = lookup(ingress.value, "protocol", "tcp")
      cidr_blocks      = [lookup(ingress.value, "cidr_block", "0.0.0.0/0")]
      ipv6_cidr_blocks = [lookup(ingress.value, "ipv6_cidr_block", "::/0")]
    }
  }
  dynamic "egress" {
    for_each = var.security_group_node_egress
    content {
      from_port        = lookup(egress.value, "from_port", 0)
      to_port          = lookup(egress.value, "to_port", 0)
      protocol         = lookup(egress.value, "protocol", "-1")
      cidr_blocks      = [lookup(egress.value, "cidr_block", "0.0.0.0/0")]
      ipv6_cidr_blocks = [lookup(egress.value, "ipv6_cidr_block", "::/0")]
    }
  }
  tags = merge({ "Name" = "${var.name}-node-sg" }, var.tags, )
}

# Security group for Kafka (AWS vpc)
resource "aws_security_group" "red5pro_kafka_sg" {
  count       = local.cluster_or_autoscale ? 1 : 0
  name        = "${var.name}-kafka-sg"
  description = "Allow inbound/outbound traffic for Kafka"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = var.security_group_kafka_ingress
    content {
      from_port        = lookup(ingress.value, "from_port", 0)
      to_port          = lookup(ingress.value, "to_port", 0)
      protocol         = lookup(ingress.value, "protocol", "tcp")
      cidr_blocks      = [lookup(ingress.value, "cidr_block", "0.0.0.0/0")]
      ipv6_cidr_blocks = [lookup(ingress.value, "ipv6_cidr_block", "::/0")]
    }
  }
  dynamic "egress" {
    for_each = var.security_group_kafka_egress
    content {
      from_port        = lookup(egress.value, "from_port", 0)
      to_port          = lookup(egress.value, "to_port", 0)
      protocol         = lookup(egress.value, "protocol", "-1")
      cidr_blocks      = [lookup(egress.value, "cidr_block", "0.0.0.0/0")]
      ipv6_cidr_blocks = [lookup(egress.value, "ipv6_cidr_block", "::/0")]
    }
  }

  tags = merge({ "Name" = "${var.name}-kafka-sg" }, var.tags, )
}

# Security group for StreamManager and Node images (AWS EC2)
resource "aws_security_group" "red5pro_images_sg" {
  count       = local.cluster || local.autoscale ? 1 : 0
  name        = "${var.name}-images-sg"
  description = "Allow inbound/outbound traffic for SM and Node images"
  vpc_id      = local.vpc_id

  ingress {
    description = "Access to SSH from 0.0.0.0/0"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ "Name" = "${var.name}-images-sg" }, var.tags, )
}

# Security group for standalone Red5Pro server (AWS EC2)
resource "aws_security_group" "red5pro_standalone_sg" {
  count       = local.standalone ? 1 : 0
  name        = "${var.name}-standalone-sg"
  description = "Allow inbound/outbound traffic for standalone Red5Pro server"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = var.security_group_standalone_ingress
    content {
      from_port        = lookup(ingress.value, "from_port", 0)
      to_port          = lookup(ingress.value, "to_port", 0)
      protocol         = lookup(ingress.value, "protocol", "tcp")
      cidr_blocks      = [lookup(ingress.value, "cidr_block", "0.0.0.0/0")]
      ipv6_cidr_blocks = [lookup(ingress.value, "ipv6_cidr_block", "::/0")]
    }
  }
  dynamic "egress" {
    for_each = var.security_group_standalone_egress
    content {
      from_port        = lookup(egress.value, "from_port", 0)
      to_port          = lookup(egress.value, "to_port", 0)
      protocol         = lookup(egress.value, "protocol", "-1")
      cidr_blocks      = [lookup(egress.value, "cidr_block", "0.0.0.0/0")]
      ipv6_cidr_blocks = [lookup(egress.value, "ipv6_cidr_block", "::/0")]
    }
  }

  tags = merge({ "Name" = "${var.name}-standalone-sg" }, var.tags, )
}

################################################################################
# Red5 Pro Standalone server (AWS EC2)
################################################################################

resource "random_password" "ssl_password_red5pro_standalone" {
  count   = local.standalone && var.https_ssl_certificate != "false" ? 1 : 0
  length  = 16
  special = false
}

# Red5 Pro standalone server instance (AWS EC2)
resource "aws_instance" "red5pro_standalone" {
  count                  = local.standalone ? 1 : 0
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.standalone_instance_type
  key_name               = local.ssh_key_name
  subnet_id              = element(local.subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.red5pro_standalone_sg[0].id]

  root_block_device {
    volume_size = var.standalone_volume_size
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home/ubuntu"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.standalone_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.standalone_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.standalone_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.standalone_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.standalone_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.standalone_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.standalone_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.standalone_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.standalone_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.standalone_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.standalone_red5pro_round_trip_auth_endpoint_invalidate}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "sudo mkdir -p /usr/local/red5pro/certs",
      "echo '${try(file(var.https_ssl_certificate_cert_path), "")}' | sudo tee -a /usr/local/red5pro/certs/fullchain.pem",
      "echo '${try(file(var.https_ssl_certificate_key_path), "")}' | sudo tee -a /usr/local/red5pro/certs/privkey.pem",
      "export SSL='${var.https_ssl_certificate}'",
      "export SSL_DOMAIN='${var.https_ssl_certificate_domain_name}'",
      "export SSL_MAIL='${var.https_ssl_certificate_email}'",
      "export SSL_PASSWORD='${try(nonsensitive(random_password.ssl_password_red5pro_standalone[0].result), "")}'",
      "export SSL_CERT_PATH=/usr/local/red5pro/certs",
      "nohup sudo -E /home/ubuntu/red5pro-installer/r5p_ssl_check_install.sh >> /home/ubuntu/red5pro-installer/r5p_ssl_check_install.log &",
      "sleep 2"
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  tags = merge({ "Name" = "${var.name}-standalone-server" }, var.tags, )

  lifecycle {
    precondition {
      condition     = fileexists(var.path_to_red5pro_build) == true
      error_message = "ERROR! Value in variable path_to_red5pro_build must be a valid! Example: /home/ubuntu/terraform-aws-red5pro/red5pro-server-0.0.0.b0-release.zip"
    }
  }
}


################################################################################
# Kafka keys and certificates
################################################################################

# Generate random admin usernames for Kafka cluster
resource "random_string" "kafka_admin_username" {
  count   = local.cluster_or_autoscale ? 1 : 0
  length  = 8
  special = false
  upper   = false
  lower   = true
  numeric = false
}

# Generate random client usernames for Kafka cluster
resource "random_string" "kafka_client_username" {
  count   = local.cluster_or_autoscale ? 1 : 0
  length  = 8
  special = false
  upper   = false
  lower   = true
  numeric = false
}

# Generate random IDs for Kafka cluster
resource "random_id" "kafka_cluster_id" {
  count       = local.cluster_or_autoscale ? 1 : 0
  byte_length = 16
}

# Generate random passwords for Kafka cluster
resource "random_id" "kafka_admin_password" {
  count       = local.cluster_or_autoscale ? 1 : 0
  byte_length = 16
}

# Generate random passwords for Kafka cluster
resource "random_id" "kafka_client_password" {
  count       = local.cluster_or_autoscale ? 1 : 0
  byte_length = 16
}

# Create private key for CA
resource "tls_private_key" "ca_private_key" {
  count     = local.cluster_or_autoscale ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create private key for kafka server certificate 
resource "tls_private_key" "kafka_server_key" {
  count     = local.cluster_or_autoscale ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create self-signed certificate for CA
resource "tls_self_signed_cert" "ca_cert" {
  count           = local.cluster_or_autoscale ? 1 : 0
  private_key_pem = tls_private_key.ca_private_key[0].private_key_pem

  is_ca_certificate = true

  subject {
    country             = "US"
    common_name         = "Infrared5, Inc."
    organization        = "Red5"
    organizational_unit = "Red5 Root Certification Auhtority"
  }

  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "cert_signing",
    "crl_signing",
  ]
}

# Create CSR for server certificate 
resource "tls_cert_request" "kafka_server_csr" {
  count           = local.cluster_or_autoscale ? 1 : 0
  private_key_pem = tls_private_key.kafka_server_key[0].private_key_pem
  ip_addresses    = [local.kafka_ip]
  dns_names       = ["kafka0"]

  subject {
    country             = "US"
    common_name         = "Kafka server"
    organization        = "Infrared5, Inc."
    organizational_unit = "Development"
  }

  depends_on = [aws_instance.red5pro_sm, aws_instance.red5pro_kafka]
}

# Sign kafka server Certificate by Private CA 
resource "tls_locally_signed_cert" "kafka_server_cert" {
  count = local.cluster_or_autoscale ? 1 : 0
  # CSR by the development servers
  cert_request_pem = tls_cert_request.kafka_server_csr[0].cert_request_pem
  # CA Private key 
  ca_private_key_pem = tls_private_key.ca_private_key[0].private_key_pem
  # CA certificate
  ca_cert_pem = tls_self_signed_cert.ca_cert[0].cert_pem

  validity_period_hours = 1 * 365 * 24

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

################################################################################
# Kafka server (AWS instance)
################################################################################

resource "aws_instance" "red5pro_kafka" {
  count                  = local.kafka_standalone_instance ? 1 : 0
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.kafka_standalone_instance_type
  key_name               = local.ssh_key_name
  subnet_id              = element(local.subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.red5pro_kafka_sg[0].id]

  root_block_device {
    volume_size = var.kafka_standalone_volume_size
  }
  tags = merge({ "Name" = "${var.name}-kafka-standalone", }, var.tags, )

}

resource "null_resource" "red5pro_kafka" {
  count = local.kafka_standalone_instance ? 1 : 0

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home/ubuntu"

    connection {
      host        = aws_instance.red5pro_kafka[0].public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }

  }

  provisioner "remote-exec" {
    inline = [
      "sudo iptables -F",
      "sudo netfilter-persistent save",
      "sudo cloud-init status --wait",
      "echo 'ssl.keystore.key=${local.kafka_ssl_keystore_key}' | sudo tee -a /home/ubuntu/red5pro-installer/server.properties",
      "echo 'ssl.truststore.certificates=${local.kafka_ssl_truststore_cert}' | sudo tee -a /home/ubuntu/red5pro-installer/server.properties",
      "echo 'ssl.keystore.certificate.chain=${local.kafka_ssl_keystore_cert_chain}' | sudo tee -a /home/ubuntu/red5pro-installer/server.properties",
      "echo 'listener.name.broker.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${nonsensitive(random_string.kafka_admin_username[0].result)}\" password=\"${nonsensitive(random_id.kafka_admin_password[0].id)}\" user_${nonsensitive(random_string.kafka_admin_username[0].result)}=\"${nonsensitive(random_id.kafka_admin_password[0].id)}\" user_${nonsensitive(random_string.kafka_client_username[0].result)}=\"${nonsensitive(random_id.kafka_client_password[0].id)}\";' | sudo tee -a /home/ubuntu/red5pro-installer/server.properties",
      "echo 'listener.name.controller.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${nonsensitive(random_string.kafka_admin_username[0].result)}\" password=\"${nonsensitive(random_id.kafka_admin_password[0].id)}\" user_${nonsensitive(random_string.kafka_admin_username[0].result)}=\"${nonsensitive(random_id.kafka_admin_password[0].id)}\" user_${nonsensitive(random_string.kafka_client_username[0].result)}=\"${nonsensitive(random_id.kafka_client_password[0].id)}\";' | sudo tee -a /home/ubuntu/red5pro-installer/server.properties",
      "echo 'advertised.listeners=BROKER://${local.kafka_ip}:9092' | sudo tee -a /home/ubuntu/red5pro-installer/server.properties",
      "export KAFKA_ARCHIVE_URL='${var.kafka_standalone_instance_arhive_url}'",
      "export KAFKA_CLUSTER_ID='${random_id.kafka_cluster_id[0].b64_std}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_kafka_install.sh",
    ]
    connection {
      host        = aws_instance.red5pro_kafka[0].public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }
  depends_on = [tls_cert_request.kafka_server_csr, aws_instance.red5pro_kafka]
}

################################################################################
# Stream manager 2.0 - (AWS EC2 instance)
################################################################################
# Generate random password for Red5 Pro Stream Manager 2.0 authentication
resource "random_password" "r5as_auth_secret" {
  count   = local.cluster_or_autoscale ? 1 : 0
  length  = 32
  special = false
}
# Stream Manager instance 
resource "aws_instance" "red5pro_sm" {
  count                  = local.cluster || local.autoscale ? 1 : 0
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.stream_manager_instance_type
  key_name               = local.ssh_key_name
  subnet_id              = element(local.subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.red5pro_sm_sg[0].id]

  root_block_device {
    volume_size = var.stream_manager_volume_size
  }
  # Metadata for the instance
  user_data = base64gzip(<<-EOF
          #!/bin/bash
          mkdir -p /usr/local/stream-manager/keys
          mkdir -p /usr/local/stream-manager/certs
          echo "${try(file(var.https_ssl_certificate_cert_path), "")}" > /usr/local/stream-manager/certs/cert.pem
          echo "${try(file(var.https_ssl_certificate_key_path), "")}" > /usr/local/stream-manager/certs/privkey.pem
          chmod 400 /usr/local/stream-manager/certs/privkey.pem
          ############################ .env file #########################################################
          cat >> /usr/local/stream-manager/.env <<- EOM
          KAFKA_CLUSTER_ID=${random_id.kafka_cluster_id[0].b64_std}
          KAFKA_ADMIN_USERNAME=${random_string.kafka_admin_username[0].result}
          KAFKA_ADMIN_PASSWORD=${random_id.kafka_admin_password[0].id}
          KAFKA_CLIENT_USERNAME=${random_string.kafka_client_username[0].result}
          KAFKA_CLIENT_PASSWORD=${random_id.kafka_client_password[0].id}
          R5AS_AUTH_SECRET=${random_password.r5as_auth_secret[0].result}
          R5AS_AUTH_USER=${var.stream_manager_auth_user}
          R5AS_AUTH_PASS=${var.stream_manager_auth_password}
          TF_VAR_aws_access_key=${var.aws_access_key}
          TF_VAR_aws_secret_key=${var.aws_secret_key}
          TF_VAR_aws_ssh_key_pair=${var.ssh_key_name}
          TF_VAR_r5p_license_key=${var.red5pro_license_key}
          TRAEFIK_TLS_CHALLENGE=${local.stream_manager_ssl == "letsencrypt" ? "true" : "false"}
          TRAEFIK_HOST=${var.https_ssl_certificate_domain_name}
          TRAEFIK_SSL_EMAIL=${var.https_ssl_certificate_email}
          TRAEFIK_CMD=${local.stream_manager_ssl == "imported" ? "--providers.file.filename=/scripts/traefik.yaml" : ""}
        EOF
  )
  tags = merge({ "Name" = "${var.name}-stream-manager", }, var.tags, )
}

resource "null_resource" "red5pro_sm" {
  count = local.cluster_or_autoscale ? 1 : 0

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home/ubuntu"

    connection {
      host        = local.stream_manager_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }
  provisioner "remote-exec" {
    inline = [
      "until sudo cloud-init status | grep 'done'; do echo 'waiting for cloud-init'; sleep 10; done",
      "echo 'KAFKA_SSL_KEYSTORE_KEY=${local.kafka_ssl_keystore_key}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'KAFKA_SSL_TRUSTSTORE_CERTIFICATES=${local.kafka_ssl_truststore_cert}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'KAFKA_SSL_KEYSTORE_CERTIFICATE_CHAIN=${local.kafka_ssl_keystore_cert_chain}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'KAFKA_REPLICAS=${local.kafka_on_sm_replicas}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'KAFKA_IP=${local.kafka_ip}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'TRAEFIK_IP=${local.stream_manager_ip}' | sudo tee -a /usr/local/stream-manager/.env",
      "export SM_SSL='${local.stream_manager_ssl}'",
      "export SM_STANDALONE='${local.stream_manager_standalone}'",
      "export SM_SSL_DOMAIN='${var.https_ssl_certificate_domain_name}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_sm2_aws.sh",
    ]
    connection {
      host        = local.stream_manager_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }

  }
  depends_on = [tls_cert_request.kafka_server_csr, aws_instance.red5pro_sm, null_resource.red5pro_kafka]
}

################################################################################
# Stream manager autoscaling - (AWS EC2)
################################################################################

# AWS Stream Manager autoscaling - Create image from StreamManager instance (AWS EC2 AMI)
resource "aws_ami_from_instance" "red5pro_sm_image" {
  count              = local.autoscale ? 1 : 0
  name               = "${var.name}-stream-manager-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  source_instance_id = aws_instance.red5pro_sm[0].id

  depends_on = [aws_instance.red5pro_sm[0], null_resource.red5pro_sm[0]]

  lifecycle {
    ignore_changes = [name, tags]
  }

  tags = merge({ "Name" = "${var.name}-stream-manager-image-${formatdate("DDMMMYY-hhmm", timestamp())}" }, var.tags, )
}

# AWS Stream Manager autoscaling - Launch template
resource "aws_launch_template" "red5pro_sm_lt" {
  count                  = local.autoscale ? 1 : 0
  name                   = "${var.name}-stream-manager-lt"
  image_id               = aws_ami_from_instance.red5pro_sm_image[0].id
  instance_type          = var.stream_manager_instance_type
  key_name               = local.ssh_key_name
  update_default_version = true

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.red5pro_sm_sg[0].id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = var.stream_manager_volume_size
    }
  }
  tag_specifications {
    resource_type = "instance"

    tags = merge({ "Name" = "${var.name}-stream-manager" }, var.tags, )
  }
}

# AWS Stream Manager autoscaling - Placement group
resource "aws_placement_group" "red5pro_sm_pg" {
  count    = local.autoscale ? 1 : 0
  name     = "${var.name}-stream-manager-pg"
  strategy = "partition" # cluster
}

# AWS Stream Manager autoscaling - Autoscaling group
resource "aws_autoscaling_group" "red5pro_sm_ag" {
  count               = local.autoscale ? 1 : 0
  name                = "${var.name}-stream-manager-ag"
  desired_capacity    = var.stream_manager_autoscaling_desired_capacity
  max_size            = var.stream_manager_autoscaling_maximum_capacity
  min_size            = var.stream_manager_autoscaling_minimum_capacity
  placement_group     = aws_placement_group.red5pro_sm_pg[0].id
  vpc_zone_identifier = local.subnet_ids

  launch_template {
    id      = aws_launch_template.red5pro_sm_lt[0].id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [
      target_group_arns,
    ]
  }
}

# AWS Stream Manager autoscaling - Target group
resource "aws_lb_target_group" "red5pro_sm_tg" {
  count       = local.autoscale ? 1 : 0
  name        = "${var.name}-stream-manager-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id

  health_check {
    path = "/"
    port = 80
  }
}

# AWS Stream Manager autoscaling - SSL certificate
data "aws_acm_certificate" "red5pro_sm_cert" {
  count    = local.autoscale && var.https_certificate_manager_use_existing ? 1 : 0
  domain   = var.https_certificate_manager_certificate_name
  statuses = ["ISSUED"]
}

# AWS Stream Manager autoscaling - Aplication Load Balancer
resource "aws_lb" "red5pro_sm_lb" {
  count              = local.autoscale ? 1 : 0
  name               = "${var.name}-stream-manager-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.red5pro_sm_sg[0].id]
  subnets            = local.subnet_ids

  enable_deletion_protection = false

  tags = merge({ "Name" = "${var.name}-stream-manager-lb" }, var.tags, )
}

# AWS Stream Manager autoscaling - LB HTTP listener
resource "aws_lb_listener" "red5pro_sm_http" {
  count             = local.autoscale ? 1 : 0
  load_balancer_arn = aws_lb.red5pro_sm_lb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.red5pro_sm_tg[0].arn
  }
}

# AWS Stream Manager autoscaling - LB HTTPS listener
resource "aws_lb_listener" "red5pro_sm_https" {
  count             = local.autoscale && var.https_certificate_manager_use_existing ? 1 : 0
  load_balancer_arn = aws_lb.red5pro_sm_lb[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.red5pro_sm_cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.red5pro_sm_tg[0].arn
  }
}

# AWS Stream Manager autoscaling - Autoscaling attachment
resource "aws_autoscaling_attachment" "red5pro_sm_aa" {
  count                  = local.autoscale ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.red5pro_sm_ag[0].id
  lb_target_group_arn    = aws_lb_target_group.red5pro_sm_tg[0].arn
}


################################################################################
# Red5 Pro Autoscaling Node - Origin/Edge/Transcoders/Relay (AWS Instance)
################################################################################

# ORIGIN Node instance for AMI (AWS EC2)
resource "aws_instance" "red5pro_node" {
  count                  = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.node_image_instance_type
  key_name               = local.ssh_key_name
  subnet_id              = element(local.subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.red5pro_images_sg[0].id]

  root_block_device {
    volume_size = var.node_image_volume_size
  }
  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home/ubuntu"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node.sh",
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  tags = merge({ "Name" = "${var.name}-node-image" }, var.tags, )
  
  lifecycle {
    precondition {
      condition     = fileexists(var.path_to_red5pro_build) == true
      error_message = "ERROR! Value in variable path_to_red5pro_build must be a valid! Example: /home/ubuntu/terraform-aws-red5pro/red5pro-server-0.0.0.b0-release.zip"
    }
  }
}


################################################################################################
# Red5 Pro autoscaling nodes create images - Origin/Edge/Transcoders/Relay (AWS Custom Images)
################################################################################################

# node - Create image (AWS EC2 AMI)
resource "aws_ami_from_instance" "red5pro_node_image" {
  count              = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  name               = "${var.name}-node-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  source_instance_id = aws_instance.red5pro_node[0].id
  depends_on         = [aws_instance.red5pro_node[0]]
  lifecycle {
    ignore_changes = [name, tags]
  }

  tags = merge({ "Name" = "${var.name}-node-image-${formatdate("DDMMMYY-hhmm", timestamp())}" }, var.tags, )
}

################################################################################
# Stop instances which used for create images (AWS CLI)
################################################################################

# AWS Stream Manager autoscaling - Stop Stream Manager instance using aws cli
resource "null_resource" "stop_stream_manager" {
  count = local.autoscale ? 1 : 0
  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.red5pro_sm[0].id} --region ${var.aws_region}"
    environment = {
      AWS_ACCESS_KEY_ID     = "${var.aws_access_key}"
      AWS_SECRET_ACCESS_KEY = "${var.aws_secret_key}"
    }
  }
  depends_on = [aws_ami_from_instance.red5pro_sm_image[0]]
}

# Stop Node instance using aws cli
resource "null_resource" "stop_node" {
  count = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.red5pro_node[0].id} --region ${var.aws_region}"
    environment = {
      AWS_ACCESS_KEY_ID     = "${var.aws_access_key}"
      AWS_SECRET_ACCESS_KEY = "${var.aws_secret_key}"
    }
  }
  depends_on = [aws_ami_from_instance.red5pro_node_image[0]]
}

################################################################################
# Create/Delete node group (Stream Manager API)
################################################################################
resource "time_sleep" "wait_for_delete_nodegroup" {
  count = local.cluster_or_autoscale && var.node_group_create ? 1 : 0
  depends_on = [
    aws_instance.red5pro_sm[0],
    aws_instance.red5pro_kafka[0],
    aws_security_group.red5pro_node_sg[0],
    aws_security_group.red5pro_kafka_sg[0],
    aws_security_group.red5pro_sm_sg[0],
    aws_internet_gateway.red5pro_igw[0],
    aws_route.red5pro_route[0],
    aws_route_table_association.red5pro_subnets_association[0],
    aws_route_table_association.red5pro_subnets_association[1],
  ]
  destroy_duration = "60s"
}

resource "null_resource" "node_group" {
  count = local.cluster_or_autoscale && var.node_group_create ? 1 : 0
  triggers = {
    trigger_name   = "node-group-trigger"
    SM_URL         = "${local.stream_manager_url}"
    R5AS_AUTH_USER = "${var.stream_manager_auth_user}"
    R5AS_AUTH_PASS = "${var.stream_manager_auth_password}"
  }
  provisioner "local-exec" {
    when    = create
    command = "bash ${abspath(path.module)}/red5pro-installer/r5p_create_node_group.sh"
    environment = {
      SM_URL                                   = "${local.stream_manager_url}"
      R5AS_AUTH_USER                           = "${var.stream_manager_auth_user}"
      R5AS_AUTH_PASS                           = "${var.stream_manager_auth_password}"
      NODE_GROUP_REGION                        = "${var.aws_region}"
      NODE_ENVIRONMENT                         = "${var.name}"
      NODE_VPC_NAME                            = "${local.vpc_name}"
      NODE_SECURITY_GROUP_NAME                 = "${aws_security_group.red5pro_node_sg[0].name}"
      NODE_IMAGE_NAME                          = "${aws_ami_from_instance.red5pro_node_image[0].name}"
      ORIGINS_MIN                              = "${var.node_group_origins_min}"
      ORIGINS_MAX                              = "${var.node_group_origins_max}"
      ORIGIN_INSTANCE_TYPE                     = "${var.node_group_origins_instance_type}"
      ORIGIN_VOLUME_SIZE                       = "${var.node_group_origins_volume_size}"
      EDGES_MIN                                = "${var.node_group_edges_min}"
      EDGES_MAX                                = "${var.node_group_edges_max}"
      EDGE_INSTANCE_TYPE                       = "${var.node_group_edges_instance_type}"
      EDGE_VOLUME_SIZE                         = "${var.node_group_edges_volume_size}"
      TRANSCODERS_MIN                          = "${var.node_group_transcoders_min}"
      TRANSCODERS_MAX                          = "${var.node_group_transcoders_max}"
      TRANSCODER_INSTANCE_TYPE                 = "${var.node_group_transcoders_instance_type}"
      TRANSCODER_VOLUME_SIZE                   = "${var.node_group_transcoders_volume_size}"
      RELAYS_MIN                               = "${var.node_group_relays_min}"
      RELAYS_MAX                               = "${var.node_group_relays_max}"
      RELAY_INSTANCE_TYPE                      = "${var.node_group_relays_instance_type}"
      RELAY_VOLUME_SIZE                        = "${var.node_group_relays_volume_size}"
      PATH_TO_JSON_TEMPLATES                   = "${abspath(path.module)}/red5pro-installer/nodegroup-json-templates"
      NODE_ROUND_TRIP_AUTH_ENABLE              = "${var.node_config_round_trip_auth.enable}"
      NODE_ROUNT_TRIP_AUTH_TARGET_NODES        = "${join(",", var.node_config_round_trip_auth.target_nodes)}"
      NODE_ROUND_TRIP_AUTH_HOST                = "${var.node_config_round_trip_auth.auth_host}"
      NODE_ROUND_TRIP_AUTH_PORT                = "${var.node_config_round_trip_auth.auth_port}"
      NODE_ROUND_TRIP_AUTH_PROTOCOL            = "${var.node_config_round_trip_auth.auth_protocol}"
      NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE   = "${var.node_config_round_trip_auth.auth_endpoint_validate}"
      NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE = "${var.node_config_round_trip_auth.auth_endpoint_invalidate}"
      NODE_WEBHOOK_ENABLE                      = "${var.node_config_webhooks.enable}"
      NODE_WEBHOOK_TARGET_NODES                = "${join(",", var.node_config_webhooks.target_nodes)}"
      NODE_WEBHOOK_ENDPOINT                    = "${var.node_config_webhooks.webhook_endpoint}"
      NODE_SOCIAL_PUSHER_ENABLE                = "${var.node_config_social_pusher.enable}"
      NODE_SOCIAL_PUSHER_TARGET_NODES          = "${join(",", var.node_config_social_pusher.target_nodes)}"
      NODE_RESTREAMER_ENABLE                   = "${var.node_config_restreamer.enable}"
      NODE_RESTREAMER_TARGET_NODES             = "${join(",", var.node_config_restreamer.target_nodes)}"
      NODE_RESTREAMER_TSINGEST                 = "${var.node_config_restreamer.restreamer_tsingest}"
      NODE_RESTREAMER_IPCAM                    = "${var.node_config_restreamer.restreamer_ipcam}"
      NODE_RESTREAMER_WHIP                     = "${var.node_config_restreamer.restreamer_whip}"
      NODE_RESTREAMER_SRTINGEST                = "${var.node_config_restreamer.restreamer_srtingest}"
    }
  }
  provisioner "local-exec" {
    when    = destroy
    command = "bash ${abspath(path.module)}/red5pro-installer/r5p_delete_node_group.sh '${self.triggers.SM_URL}' '${self.triggers.R5AS_AUTH_USER}' '${self.triggers.R5AS_AUTH_PASS}'"
  }

  depends_on = [time_sleep.wait_for_delete_nodegroup[0]]

  lifecycle {
    precondition {
      condition     = var.node_image_create == true
      error_message = "ERROR! Node group creation requires the creation of a Node image for the node group. Please set the 'node_image_create' variable to 'true' and re-run the Terraform apply."
    }
  }
}
