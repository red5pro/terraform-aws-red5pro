
################################################################################
# OUTPUTS
################################################################################

output "node_origin_image" {
  description = "AMI image name of the Red5 Pro Node Origin image"
  value = try(aws_ami_from_instance.red5pro_node_origin_image[0].name, null)
}
output "node_edge_image" {
  description = "AMI image name of the Red5 Pro Node Edge image"
  value = try(aws_ami_from_instance.red5pro_node_edge_image[0].name, null)
}
output "node_transcoder_image" {
  description = "AMI image name of the Red5 Pro Node Transcoder image"
  value = try(aws_ami_from_instance.red5pro_node_transcoder_image[0].name, null)
}
output "node_relay_image" {
  description = "AMI image name of the Red5 Pro Node Relay image"
  value = try(aws_ami_from_instance.red5pro_node_relay_image[0].name , null)
}
# output "single" {
#   description = "Deployment type - single"
#   value = local.single
# }
# output "cluster" {
#   description = "Deployment type - cluster"
#   value = local.cluster
# }
# output "autoscaling" {
#   description = "Deployment type - autoscaling"
#   value = local.autoscaling
# }
output "ssh_key_name" {
  description = "SSH key name"
  value = local.ssh_key_name
}
output "vpc_id" {
  description = "VPC ID"
  value = local.vpc_id
}
output "vpc_name" {
  description = "VPC Name"
  value = local.vpc_name
}
output "subnet_ids" {
  description = "Subnet IDs"
  value = local.subnet_ids
}
output "mysql_rds_create" {
  description = "Create MySQL RDS instance"
  value = local.mysql_rds_create
}
output "mysql_host" {
  description = "MySQL host"
  value = local.mysql_host
}
output "mysql_local_enable" {
  description = "Enable local MySQL"
  value = local.mysql_local_enable
}
output "stream_manager_ip" {
  description = "Stream Manager IP"
  value = local.cluster ? local.stream_manager_ip : null
}
output "stream_manager_http_url" {
  description = "Stream Manager HTTP URL"
  value = local.cluster ? "http://${local.stream_manager_ip}:5080" : null
}
output "stream_manager_https_url" {
  description = "Stream Manager HTTPS URL"
  value = local.cluster ? var.https_letsencrypt_enable ? "https://${var.https_letsencrypt_certificate_domain_name}:443" : null : null
}
output "load_balancer_dns_name" {
  description = "Load Balancer DNS Name"
  value = local.autoscaling ? local.stream_manager_ip : null
}
output "load_balancer_http_url" {
  description = "Load Balancer HTTP URL"
  value = local.autoscaling ? "http://${local.stream_manager_ip}:5080" : null
}
output "load_balancer_https_url" {
  description = "Load Balancer HTTPS URL"
  value = local.autoscaling ? var.https_certificate_manager_use_existing ? "https://${var.https_certificate_manager_certificate_name}:443" : null : null
}
output "single_red5pro_server_ip" {
  description = "Single Red5 Pro Server IP"
  value = local.single ? local.elastic_ip : null
}
output "single_red5pro_server_http_url" {
  description = "Single Red5 Pro Server HTTP URL"
  value = local.single ? "http://${local.elastic_ip}:5080" : null
}
output "single_red5pro_server_https_url" {
  description = "Single Red5 Pro Server HTTPS URL"
  value = local.single && var.https_letsencrypt_enable ? "https://${var.https_letsencrypt_certificate_domain_name}:443" : null
}
output "ssh_private_key_path" {
  description = "SSH private key path"
  value = local.ssh_private_key_path
}
