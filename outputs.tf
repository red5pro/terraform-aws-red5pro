
################################################################################
# OUTPUTS
################################################################################

output "node_image_name" {
  description = "AMI image name of the Red5 Pro Node image"
  value       = try(aws_ami_from_instance.red5pro_node_image[0].name, null)
}
output "node_image_id" {
  description = "AMI image ID of the Red5 Pro Node image"
  value       = try(aws_ami_from_instance.red5pro_node_image[0].id, null)
}
output "ssh_key_name" {
  description = "SSH key name"
  value       = local.ssh_key_name
}
output "vpc_id" {
  description = "VPC ID"
  value       = local.vpc_id
}
output "vpc_name" {
  description = "VPC Name"
  value       = local.vpc_name
}
output "subnet_ids" {
  description = "Subnet IDs"
  value       = local.subnet_ids
}
output "stream_manager_ip" {
  description = "Stream Manager IP"
  value       = local.cluster ? local.stream_manager_ip : null
}
output "stream_manager_http_url" {
  description = "Stream Manager HTTP URL"
  value       = local.cluster ? "http://${local.stream_manager_ip}:5080" : null
}
output "stream_manager_https_url" {
  description = "Stream Manager HTTPS URL"
  value       = local.cluster ? var.https_letsencrypt_enable ? "https://${var.https_letsencrypt_certificate_domain_name}:443" : null : null
}
output "load_balancer_dns_name" {
  description = "Load Balancer DNS Name"
  value       = local.autoscale ? local.stream_manager_ip : null
}
output "load_balancer_http_url" {
  description = "Load Balancer HTTP URL"
  value       = local.autoscale ? "http://${local.stream_manager_ip}:5080" : null
}
output "load_balancer_https_url" {
  description = "Load Balancer HTTPS URL"
  value       = local.autoscale ? var.https_certificate_manager_use_existing ? "https://${var.https_certificate_manager_certificate_name}:443" : null : null
}
output "standalone_red5pro_server_ip" {
  description = "standalone Red5 Pro Server IP"
  value       = local.standalone ? local.elastic_ip : null
}
output "standalone_red5pro_server_http_url" {
  description = "standalone Red5 Pro Server HTTP URL"
  value       = local.standalone ? "http://${local.elastic_ip}:5080" : null
}
output "standalone_red5pro_server_https_url" {
  description = "standalone Red5 Pro Server HTTPS URL"
  value       = local.standalone && var.https_letsencrypt_enable ? "https://${var.https_letsencrypt_certificate_domain_name}:443" : null
}
output "ssh_private_key_path" {
  description = "SSH private key path"
  value       = local.ssh_private_key_path
}
output "standalone_red5pro_server_brew_mixer_controller_page_url" {
  description = "standalone Red5 Pro Server Brew Mixer Controller Page URL"
  value       = local.standalone && var.red5pro_brew_mixer_enable ? "https://${var.https_letsencrypt_certificate_domain_name}/brewmixer/rtController.html" : null
}
##########################
#################
output "key_name" {
  value = var.ssh_key_name
}

output "matched_keys" {
  value = data.aws_key_pair.ssh_key_pair[*].key_name
}