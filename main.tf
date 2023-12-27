locals {
  single        = var.type == "single" ? true : false
  cluster       = var.type == "cluster" ? true : false
  autoscaling   = var.type == "autoscaling" ? true : false

  ssh_key_name    = var.ssh_key_create ? aws_key_pair.red5pro_ssh_key[0].key_name : data.aws_key_pair.ssh_key_pair[0].key_name
  ssh_private_key = var.ssh_key_create ? tls_private_key.red5pro_ssh_key[0].private_key_pem : file(var.ssh_private_key_path)
  ssh_private_key_path = var.ssh_key_create ? local_file.red5pro_ssh_key_pem[0].filename : var.ssh_private_key_path
  
  vpc_id     = var.vpc_create ? aws_vpc.red5pro_vpc[0].id : var.vpc_id_existing
  vpc_name   = var.vpc_create ? aws_vpc.red5pro_vpc[0].tags.Name : data.aws_vpc.selected[0].tags.Name
  subnet_ids = var.vpc_create ? tolist(aws_subnet.red5pro_subnets[*].id) : data.aws_subnets.all[0].ids

  mysql_rds_create   = local.autoscaling ? true : local.cluster && var.mysql_rds_create ? true : false
  mysql_host         = local.autoscaling ? aws_db_instance.red5pro_mysql[0].address : var.mysql_rds_create ? aws_db_instance.red5pro_mysql[0].address : "localhost"
  mysql_local_enable = local.autoscaling ? false : var.mysql_rds_create ? false : true

  elastic_ip = local.autoscaling ? null : var.elastic_ip_create ? aws_eip.elastic_ip[0].public_ip : data.aws_eip.elastic_ip[0].public_ip
  stream_manager_ip = local.autoscaling ? aws_lb.red5pro_sm_lb[0].dns_name : local.elastic_ip
}


################################################################################
# Elastic IP
################################################################################

resource "aws_eip" "elastic_ip" {
  count = local.autoscaling ? 0 : var.elastic_ip_create ? 1 : 0
}

data "aws_eip" "elastic_ip" {
  count     = local.autoscaling ? 0 : var.elastic_ip_create ? 0 : 1
  public_ip = var.elastic_ip_existing
  
}

resource "aws_eip_association" "elastic_ip_association" {
  count         = local.single || local.cluster ? 1 : 0
  instance_id   = local.single ? aws_instance.red5pro_single[0].id : aws_instance.red5pro_sm[0].id
  allocation_id = var.elastic_ip_create ? aws_eip.elastic_ip[0].id : data.aws_eip.elastic_ip[0].id
}


################################################################################
# SSH_KEY
################################################################################

# SSH key pair generation
resource "tls_private_key" "red5pro_ssh_key" {
  count     = var.ssh_key_create ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Import SSH key pair to AWS
resource "aws_key_pair" "red5pro_ssh_key" {
  count      = var.ssh_key_create ? 1 : 0
  key_name   = var.ssh_key_name
  public_key = tls_private_key.red5pro_ssh_key[0].public_key_openssh
}

# Save SSH key pair files to local folder
resource "local_file" "red5pro_ssh_key_pem" {
  count           = var.ssh_key_create ? 1 : 0
  filename        = "./${var.ssh_key_name}.pem"
  content         = tls_private_key.red5pro_ssh_key[0].private_key_pem
  file_permission = "0400"
}
resource "local_file" "red5pro_ssh_key_pub" {
  count    = var.ssh_key_create ? 1 : 0
  filename = "./${var.ssh_key_name}.pub"
  content  = tls_private_key.red5pro_ssh_key[0].public_key_openssh
}

# Check current SSH key pair on the AWS
data "aws_key_pair" "ssh_key_pair" {
  count    = var.ssh_key_create ? 0 : 1
  key_name = var.ssh_key_name
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
# Security Groups - Create new (MySQL + StreamManager + Nodes)
################################################################################

# Security group for Red5Pro Stream Manager (AWS VPC)
resource "aws_security_group" "red5pro_sm_sg" {
  count      = local.cluster || local.autoscaling ? 1 : 0
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
  count      = local.cluster || local.autoscaling ? 1 : 0
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

# Security group for MySQL database (AWS RDS)
resource "aws_security_group" "red5pro_mysql_sg" {
  count      = local.mysql_rds_create ? 1 : 0
  name        = "${var.name}-mysql-sg"
  description = "Allow inbound/outbound traffic for MySQL"
  vpc_id      = local.vpc_id

  ingress {
    description      = "Access to MySQL from Stream Manager security group"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.red5pro_sm_sg[0].id, aws_security_group.red5pro_images_sg[0].id]
    }
  egress {
    description      = "Access from MySQL to 0.0.0.0/0"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge({ "Name" = "${var.name}-mysql-sg" }, var.tags, )
}

# Security group for StreamManager and Node images (AWS RDS)
resource "aws_security_group" "red5pro_images_sg" {
  count      = local.cluster || local.autoscaling ? 1 : 0
  name        = "${var.name}-images-sg"
  description = "Allow inbound/outbound traffic for SM and Node images"
  vpc_id      = local.vpc_id

  ingress {
    description      = "Access to SSH from 0.0.0.0/0"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ "Name" = "${var.name}-images-sg" }, var.tags, )
}

# Security group for Single Red5Pro server (AWS EC2)
resource "aws_security_group" "red5pro_single_sg" {
  count       = local.single && var.security_group_create ? 1 : 0
  name        = "${var.name}-single-sg"
  description = "Allow inbound/outbound traffic for Single Red5Pro server"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = var.security_group_single_ingress
    content {
      from_port        = lookup(ingress.value, "from_port", 0)
      to_port          = lookup(ingress.value, "to_port", 0)
      protocol         = lookup(ingress.value, "protocol", "tcp")
      cidr_blocks      = [lookup(ingress.value, "cidr_block", "0.0.0.0/0")]
      ipv6_cidr_blocks = [lookup(ingress.value, "ipv6_cidr_block", "::/0")]
    }
  }
  dynamic "egress" {
    for_each = var.security_group_single_egress
    content {
      from_port        = lookup(egress.value, "from_port", 0)
      to_port          = lookup(egress.value, "to_port", 0)
      protocol         = lookup(egress.value, "protocol", "-1")
      cidr_blocks      = [lookup(egress.value, "cidr_block", "0.0.0.0/0")]
      ipv6_cidr_blocks = [lookup(egress.value, "ipv6_cidr_block", "::/0")]
    }
  }

  tags = merge({ "Name" = "${var.name}-single-sg" }, var.tags, )
}

################################################################################
# MySQL - Create new (AWS RDS)
################################################################################

# MySQL DataBase subnet group (AWS RDS)
resource "aws_db_subnet_group" "red5pro_mysql_subnet_group" {
  count      = local.mysql_rds_create ? 1 : 0
  name       = "${var.name}-mysql-subnet-group"
  subnet_ids = local.subnet_ids
  tags       = merge({ "Name" = "${var.name}-mysql-subnet-group" }, var.tags, )
}

# MySQL DataBase parameter group (AWS RDS)
resource "aws_db_parameter_group" "red5pro_mysql_pg" {
  count  = local.mysql_rds_create ? 1 : 0
  name   = "${var.name}-mysql-pg"
  family = "mysql8.0"

  parameter {
    name  = "max_connections"
    value = "100000"
  }
  tags = merge({ "Name" = "${var.name}-mysql-pg" }, var.tags, )
}

# MySQL DataBase (AWS RDS)
resource "aws_db_instance" "red5pro_mysql" {
  count                  = local.mysql_rds_create ? 1 : 0
  identifier             = "${var.name}-mysql"
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.mysql_rds_instance_type
  username               = var.mysql_user_name
  password               = var.mysql_password
  port                   = var.mysql_port
  parameter_group_name   = aws_db_parameter_group.red5pro_mysql_pg[0].name
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.red5pro_mysql_subnet_group[0].name
  vpc_security_group_ids = [aws_security_group.red5pro_mysql_sg[0].id]

  tags = merge({ "Name" = "${var.name}-mysql" }, var.tags, )
}

################################################################################
# Stream manager - (AWS EC2 instance)
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

# Stream Manager instance 
resource "aws_instance" "red5pro_sm" {
  count                  = local.cluster || local.autoscaling ? 1 : 0
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.stream_manager_instance_type
  key_name               = local.ssh_key_name
  subnet_id              = element(local.subnet_ids, 0)
  vpc_security_group_ids = [local.cluster ? aws_security_group.red5pro_sm_sg[0].id : aws_security_group.red5pro_images_sg[0].id]

  root_block_device {
    volume_size = var.stream_manager_volume_size
  }

  provisioner "file" {
    source        = "${abspath(path.module)}/red5pro-installer"
    destination   = "/home/ubuntu"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  provisioner "file" {
    source        = var.path_to_red5pro_build
    destination   = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  provisioner "file" {
    source        = var.path_to_aws_cloud_controller
    destination   = "/home/ubuntu/red5pro-installer/${basename(var.path_to_aws_cloud_controller)}"

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
      "export SM_API_KEY='${var.stream_manager_api_key}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_PREFIX_NAME='${var.name}-node'",
      "export DB_LOCAL_ENABLE='${local.mysql_local_enable}'",
      "export DB_HOST='${local.mysql_host}'",
      "export DB_PORT='${var.mysql_port}'",
      "export DB_USER='${var.mysql_user_name}'",
      "export DB_PASSWORD='${var.mysql_password}'",
      "export AWS_DEFAULT_ZONE='${var.aws_region}'",
      "export AWS_ACCESS_KEY='${var.aws_access_key}'",
      "export AWS_SECRET_KEY='${var.aws_secret_key}'",
      "export AWS_SSH_KEY_NAME='${local.ssh_key_name}'",
      "export AWS_SECURITY_GROUP_NAME='${aws_security_group.red5pro_node_sg[0].name}'",
      "export AWS_VPC_NAME='${local.vpc_name}'",
      "export SSL_ENABLE='${var.https_letsencrypt_enable}'",
      "export SSL_DOMAIN='${var.https_letsencrypt_certificate_domain_name}'",
      "export SSL_MAIL='${var.https_letsencrypt_certificate_email}'",
      "export SSL_PASSWORD='${var.https_letsencrypt_certificate_password}'",
      "export COTURN_ENABLE='${var.stream_manager_coturn_enable}'",
      "export COTURN_ADDRESS='${var.stream_manager_coturn_address}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_mysql_local.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_stream_manager.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_coturn.sh",
      #"sudo rm -R /home/ubuntu/red5pro-installer",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
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

  tags = merge({ "Name" = "${var.name}-stream-manager", }, var.tags, )
}


################################################################################
# Stream manager autoscaling - (AWS EC2)
################################################################################

# AWS Stream Manager autoscaling - Create image from StreamManager instance (AWS EC2 AMI)
resource "aws_ami_from_instance" "red5pro_sm_image" {
  count              = local.autoscaling ? 1 : 0
  name               = "${var.name}-stream-manager-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  source_instance_id = aws_instance.red5pro_sm[0].id
  depends_on         = [aws_instance.red5pro_sm[0]]
  lifecycle {
    ignore_changes = [name, tags]
  }

  tags = merge({ "Name" = "${var.name}-stream-manager-image-${formatdate("DDMMMYY-hhmm", timestamp())}" }, var.tags, )
}

# AWS Stream Manager autoscaling - Launch template
resource "aws_launch_template" "red5pro_sm_lt" {
  count                  = local.autoscaling ? 1 : 0
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
  count    = local.autoscaling ? 1 : 0
  name     = "${var.name}-stream-manager-pg"
  strategy = "partition" # cluster
}

# AWS Stream Manager autoscaling - Autoscaling group
resource "aws_autoscaling_group" "red5pro_sm_ag" {
  count               = local.autoscaling ? 1 : 0
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
  count       = local.autoscaling ? 1 : 0
  name        = "${var.name}-stream-manager-tg"
  target_type = "instance"
  port        = 5080
  protocol    = "HTTP"
  vpc_id      = local.vpc_id

  health_check {
    path = "/"
    port = 5080
  }
}

# AWS Stream Manager autoscaling - SSL certificate
data "aws_acm_certificate" "red5pro_sm_cert" {
  count    = local.autoscaling && var.https_certificate_manager_use_existing ? 1 : 0
  domain   = var.https_certificate_manager_certificate_name
  statuses = ["ISSUED"]
}

# AWS Stream Manager autoscaling - Aplication Load Balancer
resource "aws_lb" "red5pro_sm_lb" {
  count              = local.autoscaling ? 1 : 0
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
  count             = local.autoscaling ? 1 : 0
  load_balancer_arn = aws_lb.red5pro_sm_lb[0].arn
  port              = "5080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.red5pro_sm_tg[0].arn
  }
}

# AWS Stream Manager autoscaling - LB HTTPS listener
resource "aws_lb_listener" "red5pro_sm_https" {
  count             = local.autoscaling && var.https_certificate_manager_use_existing ? 1 : 0
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
  count             = local.autoscaling ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.red5pro_sm_ag[0].id
  lb_target_group_arn    = aws_lb_target_group.red5pro_sm_tg[0].arn
}


################################################################################
# Red5 Pro autoscaling nodes (AWS EC2 AMI)
################################################################################

# ORIGIN Node instance for AMI (AWS EC2)
resource "aws_instance" "red5pro_node_origin" {
  count                  = var.origin_image_create ? 1 : 0
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.origin_image_instance_type
  key_name               = local.ssh_key_name
  subnet_id              = element(local.subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.red5pro_images_sg[0].id]

  root_block_device {
    volume_size = var.origin_image_volume_size
  }

  provisioner "file" {
    source        = "${abspath(path.module)}/red5pro-installer"
    destination   = "/home/ubuntu"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  provisioner "file" {
    source        = var.path_to_red5pro_build
    destination   = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"

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
      "export SM_IP='${local.stream_manager_ip}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.origin_image_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.origin_image_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.origin_image_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.origin_image_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.origin_image_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.origin_image_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.origin_image_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.origin_image_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.origin_image_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.origin_image_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.origin_image_red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.origin_image_red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_AWS_ACCESS_KEY='${var.origin_image_red5pro_cloudstorage_aws_access_key}'",
      "export NODE_CLOUDSTORAGE_AWS_SECRET_KEY='${var.origin_image_red5pro_cloudstorage_aws_secret_key}'",
      "export NODE_CLOUDSTORAGE_AWS_BUCKET_NAME='${var.origin_image_red5pro_cloudstorage_aws_bucket_name}'",
      "export NODE_CLOUDSTORAGE_AWS_REGION='${var.origin_image_red5pro_cloudstorage_aws_region}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.origin_image_red5pro_cloudstorage_postprocessor_enable}'",
      "export NODE_CLOUDSTORAGE_AWS_BUCKET_ACL_POLICY='${var.origin_image_red5pro_cloudstorage_aws_bucket_acl_policy}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo rm -R /home/ubuntu/red5pro-installer"
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  tags = merge({ "Name" = "${var.name}-node-origin-image" }, var.tags, )
}

# EDGE Node instance for AMI (AWS EC2)
resource "aws_instance" "red5pro_node_edge" {
  count                  = var.edge_image_create ? 1 : 0
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.edge_image_instance_type
  key_name               = local.ssh_key_name
  subnet_id              = element(local.subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.red5pro_images_sg[0].id]

  root_block_device {
    volume_size = var.edge_image_volume_size
  }

  provisioner "file" {
    source        = "${abspath(path.module)}/red5pro-installer"
    destination   = "/home/ubuntu"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  provisioner "file" {
    source        = var.path_to_red5pro_build
    destination   = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"

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
      "export SM_IP='${local.stream_manager_ip}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.edge_image_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.edge_image_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.edge_image_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.edge_image_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.edge_image_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.edge_image_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.edge_image_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.edge_image_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.edge_image_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.edge_image_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.edge_image_red5pro_round_trip_auth_endpoint_invalidate}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo rm -R /home/ubuntu/red5pro-installer"
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  tags = merge({ "Name" = "${var.name}-node-edge-image" }, var.tags, )
}

# TRANSCODER Node instance for AMI (AWS EC2)
resource "aws_instance" "red5pro_node_transcoder" {
  count                  = var.transcoder_image_create ? 1 : 0
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.transcoder_image_instance_type
  key_name               = local.ssh_key_name
  subnet_id              = element(local.subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.red5pro_images_sg[0].id]

  root_block_device {
    volume_size = var.transcoder_image_volume_size
  }

  provisioner "file" {
    source        = "${abspath(path.module)}/red5pro-installer"
    destination   = "/home/ubuntu"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  provisioner "file" {
    source        = var.path_to_red5pro_build
    destination   = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"

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
      "export SM_IP='${local.stream_manager_ip}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.transcoder_image_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.transcoder_image_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.transcoder_image_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.transcoder_image_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.transcoder_image_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.transcoder_image_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.transcoder_image_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.transcoder_image_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.transcoder_image_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.transcoder_image_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.transcoder_image_red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.transcoder_image_red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_AWS_ACCESS_KEY='${var.transcoder_image_red5pro_cloudstorage_aws_access_key}'",
      "export NODE_CLOUDSTORAGE_AWS_SECRET_KEY='${var.transcoder_image_red5pro_cloudstorage_aws_secret_key}'",
      "export NODE_CLOUDSTORAGE_AWS_BUCKET_NAME='${var.transcoder_image_red5pro_cloudstorage_aws_bucket_name}'",
      "export NODE_CLOUDSTORAGE_AWS_REGION='${var.transcoder_image_red5pro_cloudstorage_aws_region}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.transcoder_image_red5pro_cloudstorage_postprocessor_enable}'",
      "export NODE_CLOUDSTORAGE_AWS_BUCKET_ACL_POLICY='${var.transcoder_image_red5pro_cloudstorage_aws_bucket_acl_policy}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo rm -R /home/ubuntu/red5pro-installer"
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  tags = merge({ "Name" = "${var.name}-node-transcoder-image" }, var.tags, )
}

# RELAY Node instance for AMI (AWS EC2)
resource "aws_instance" "red5pro_node_relay" {
  count                  = var.relay_image_create ? 1 : 0
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.relay_image_instance_type
  key_name               = local.ssh_key_name
  subnet_id              = element(local.subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.red5pro_images_sg[0].id]

  root_block_device {
    volume_size = var.relay_image_volume_size
  }

  provisioner "file" {
    source        = "${abspath(path.module)}/red5pro-installer"
    destination   = "/home/ubuntu"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  provisioner "file" {
    source        = var.path_to_red5pro_build
    destination   = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"

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
      "export SM_IP='${local.stream_manager_ip}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.relay_image_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.relay_image_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.relay_image_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.relay_image_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.relay_image_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.relay_image_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.relay_image_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.relay_image_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.relay_image_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.relay_image_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.relay_image_red5pro_round_trip_auth_endpoint_invalidate}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo rm -R /home/ubuntu/red5pro-installer"
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  tags = merge({ "Name" = "${var.name}-node-relay-image" }, var.tags, )
}


################################################################################
# Red5 Pro Single server (AWS EC2)
################################################################################

# Red5 Pro Single server instance (AWS EC2)
resource "aws_instance" "red5pro_single" {
  count                  = local.single ? 1 : 0
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.single_instance_type
  key_name               = local.ssh_key_name
  subnet_id              = element(local.subnet_ids, 0)
  vpc_security_group_ids = [ var.security_group_create ? aws_security_group.red5pro_single_sg[0].id : var.security_group_id_existing ]

  root_block_device {
    volume_size = var.single_volume_size
  }

  provisioner "file" {
    source        = "${abspath(path.module)}/red5pro-installer"
    destination   = "/home/ubuntu"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.ssh_private_key
    }
  }

  provisioner "file" {
    source        = var.path_to_red5pro_build
    destination   = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"

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
      "export NODE_INSPECTOR_ENABLE='${var.red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_AWS_ACCESS_KEY='${var.red5pro_cloudstorage_aws_access_key}'",
      "export NODE_CLOUDSTORAGE_AWS_SECRET_KEY='${var.red5pro_cloudstorage_aws_secret_key}'",
      "export NODE_CLOUDSTORAGE_AWS_BUCKET_NAME='${var.red5pro_cloudstorage_aws_bucket_name}'",
      "export NODE_CLOUDSTORAGE_AWS_REGION='${var.red5pro_cloudstorage_aws_region}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.red5pro_cloudstorage_postprocessor_enable}'",
      "export NODE_CLOUDSTORAGE_AWS_BUCKET_ACL_POLICY='${var.red5pro_cloudstorage_aws_bucket_acl_policy}'",
      "export SSL_ENABLE='${var.https_letsencrypt_enable}'",
      "export SSL_DOMAIN='${var.https_letsencrypt_certificate_domain_name}'",
      "export SSL_MAIL='${var.https_letsencrypt_certificate_email}'",
      "export SSL_PASSWORD='${var.https_letsencrypt_certificate_password}'",
      "export COTURN_ENABLE='${var.red5pro_coturn_enable}'",
      "export COTURN_ADDRESS='${var.red5pro_coturn_address}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_coturn.sh",
      #"sudo rm -R /home/ubuntu/red5pro-installer",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
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

  tags = merge({ "Name" = "${var.name}-single-server" }, var.tags, )
}


################################################################################
# Red5 Pro autoscaling nodes create images (AWS EC2 AMI)
################################################################################

# Origin node - Create image (AWS EC2 AMI)
resource "aws_ami_from_instance" "red5pro_node_origin_image" {
  count              = var.origin_image_create ? 1 : 0
  name               = "${var.name}-node-origin-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  source_instance_id = aws_instance.red5pro_node_origin[0].id
  depends_on         = [aws_instance.red5pro_node_origin[0]]
  lifecycle {
    ignore_changes = [name, tags]
  }

  tags = merge({ "Name" = "${var.name}-node-origin-image-${formatdate("DDMMMYY-hhmm", timestamp())}" }, var.tags, )
}

# Edge node - Create image (AWS EC2 AMI)
resource "aws_ami_from_instance" "red5pro_node_edge_image" {
  count              = var.edge_image_create ? 1 : 0
  name               = "${var.name}-node-edge-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  source_instance_id = aws_instance.red5pro_node_edge[0].id
  depends_on         = [aws_instance.red5pro_node_edge[0]]
  lifecycle {
    ignore_changes = [name, tags]
  }

  tags = merge({ "Name" = "${var.name}-node-edge-image-${formatdate("DDMMMYY-hhmm", timestamp())}" }, var.tags, )
}
# Transcoder node - Create image (AWS EC2 AMI)
resource "aws_ami_from_instance" "red5pro_node_transcoder_image" {
  count              = var.transcoder_image_create ? 1 : 0
  name               = "${var.name}-node-transcoder-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  source_instance_id = aws_instance.red5pro_node_transcoder[0].id
  depends_on         = [aws_instance.red5pro_node_transcoder[0]]
  lifecycle {
    ignore_changes = [name, tags]
  }

  tags = merge({ "Name" = "${var.name}-node-transcoder-image-${formatdate("DDMMMYY-hhmm", timestamp())}" }, var.tags, )
}
# Relay node - Create image (AWS EC2 AMI)
resource "aws_ami_from_instance" "red5pro_node_relay_image" {
  count              = var.relay_image_create ? 1 : 0
  name               = "${var.name}-node-relay-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  source_instance_id = aws_instance.red5pro_node_relay[0].id
  depends_on         = [aws_instance.red5pro_node_relay[0]]
  lifecycle {
    ignore_changes = [name, tags]
  }

  tags = merge({ "Name" = "${var.name}-node-relay-image-${formatdate("DDMMMYY-hhmm", timestamp())}" }, var.tags, )
}

################################################################################
# Stop instances which used for create images (AWS CLI)
################################################################################

# AWS Stream Manager autoscaling - Stop Stream Manager instance using aws cli
resource "null_resource" "stop_stream_manager" {
  count              = local.autoscaling ? 1 : 0
  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.red5pro_sm[0].id} --region ${var.aws_region}"
    environment = {
      AWS_ACCESS_KEY_ID = "${var.aws_access_key}"
      AWS_SECRET_ACCESS_KEY = "${var.aws_secret_key}"
    }
  }
  depends_on = [aws_ami_from_instance.red5pro_sm_image[0]]
}

# Stop Origin Node instance using aws cli
resource "null_resource" "stop_node_origin" {
  count              = var.origin_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.red5pro_node_origin[0].id} --region ${var.aws_region}"
    environment = {
      AWS_ACCESS_KEY_ID = "${var.aws_access_key}"
      AWS_SECRET_ACCESS_KEY = "${var.aws_secret_key}"
    }
  }
  depends_on = [aws_ami_from_instance.red5pro_node_origin_image[0]]
}
# Stop Edge Node instance using aws cli
resource "null_resource" "stop_node_edge" {
  count              = var.edge_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.red5pro_node_edge[0].id} --region ${var.aws_region}"
    environment = {
      AWS_ACCESS_KEY_ID = "${var.aws_access_key}"
      AWS_SECRET_ACCESS_KEY = "${var.aws_secret_key}"
    }
  }
  depends_on = [aws_ami_from_instance.red5pro_node_edge_image[0]]
}
# Stop Transcoder Node instance using aws cli
resource "null_resource" "stop_node_transcoder" {
  count              = var.transcoder_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.red5pro_node_transcoder[0].id} --region ${var.aws_region}"
    environment = {
      AWS_ACCESS_KEY_ID = "${var.aws_access_key}"
      AWS_SECRET_ACCESS_KEY = "${var.aws_secret_key}"
    }
  }
  depends_on = [aws_ami_from_instance.red5pro_node_transcoder_image[0]]
}
# Stop Relay Node instance using aws cli
resource "null_resource" "stop_node_relay" {
  count              = var.relay_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.red5pro_node_relay[0].id} --region ${var.aws_region}"
    environment = {
      AWS_ACCESS_KEY_ID = "${var.aws_access_key}"
      AWS_SECRET_ACCESS_KEY = "${var.aws_secret_key}"
    }
  }
  depends_on = [aws_ami_from_instance.red5pro_node_relay_image[0]]
}

################################################################################
# Create node group (Stream Manager API)
################################################################################

resource "null_resource" "node_group" {
  count = var.node_group_create ? 1 : 0
  triggers = {
    trigger_name  = "node-group-trigger"
    SM_IP = "${local.stream_manager_ip}"
    SM_API_KEY = "${var.stream_manager_api_key}"
  }
  provisioner "local-exec" {
    when    = create
    command = "bash ${abspath(path.module)}/red5pro-installer/r5p_create_node_group.sh"
    environment = {
      NAME = "${var.name}"
      SM_IP = "${local.stream_manager_ip}"
      SM_API_KEY = "${var.stream_manager_api_key}"
      NODE_GROUP_REGION ="${var.aws_region}"
      NODE_GROUP_NAME = "${var.node_group_name}"
      ORIGINS = "${var.node_group_origins}"
      EDGES = "${var.node_group_edges}"
      TRANSCODERS = "${var.node_group_transcoders}"
      RELAYS = "${var.node_group_relays}"
      ORIGIN_INSTANCE_TYPE = "${var.node_group_origins_instance_type}"
      EDGE_INSTANCE_TYPE = "${var.node_group_edges_instance_type}"
      TRANSCODER_INSTANCE_TYPE = "${var.node_group_transcoders_instance_type}"
      RELAY_INSTANCE_TYPE = "${var.node_group_relays_instance_type}"
      ORIGIN_CAPACITY = "${var.node_group_origins_capacity}"
      EDGE_CAPACITY = "${var.node_group_edges_capacity}"
      TRANSCODER_CAPACITY = "${var.node_group_transcoders_capacity}"
      RELAY_CAPACITY = "${var.node_group_relays_capacity}"
      ORIGIN_IMAGE_NAME = "${try(aws_ami_from_instance.red5pro_node_origin_image[0].name, null)}"
      EDGE_IMAGE_NAME = "${try(aws_ami_from_instance.red5pro_node_edge_image[0].name, null)}"
      TRANSCODER_IMAGE_NAME = "${try(aws_ami_from_instance.red5pro_node_transcoder_image[0].name, null)}"
      RELAY_IMAGE_NAME = "${try(aws_ami_from_instance.red5pro_node_relay_image[0].name, null)}"
    }
  }
    provisioner "local-exec" {
    when    = destroy
    command = "bash ${abspath(path.module)}/red5pro-installer/r5p_delete_node_group.sh '${self.triggers.SM_IP}' '${self.triggers.SM_API_KEY}'"
  }

  depends_on = [aws_instance.red5pro_sm[0], aws_autoscaling_group.red5pro_sm_ag[0]]
}
