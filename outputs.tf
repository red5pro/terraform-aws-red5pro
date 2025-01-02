
################################################################################
# OUTPUTS
################################################################################

output "ssh_key_name" {
  description = "SSH key name"
  value       = local.ssh_key_name
}
output "ssh_private_key_path" {
  value = local.ssh_private_key_path
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
  description = "Stream Manager 2.0 Public IP or Load Balancer Public IP"
  value       = local.cluster_or_autoscale ? local.stream_manager_ip : ""
}
output "stream_manager_url_http" {
  description = "Stream Manager HTTP URL"
  value       = local.cluster_or_autoscale ? "http://${local.stream_manager_ip}:80" : ""
}
output "stream_manager_url_https" {
  description = "Stream Manager HTTPS URL"
  value       = local.cluster_or_autoscale && var.https_ssl_certificate != "none" ? "https://${var.https_ssl_certificate_domain_name}:443" : ""
}
output "stream_manager_red5pro_node_image" {
  description = "Stream Manager 2.0 Red5 Pro Node Image (AWS AMI)"
  value       = try(aws_ami_from_instance.red5pro_node_image[0].name, "")
}
output "standalone_red5pro_server_ip" {
  description = "Standalone Red5 Pro Server IP"
  value       = local.standalone ? local.standalone_elastic_ip : null
}
output "standalone_red5pro_server_http_url" {
  description = "Standalone Red5 Pro Server HTTP URL"
  value       = local.standalone ? "http://${local.standalone_elastic_ip}:5080" : null
}
output "standalone_red5pro_server_https_url" {
  description = "standalone Red5 Pro Server HTTPS URL"
  value       = local.standalone && var.https_ssl_certificate != "none" ? "https://${var.https_ssl_certificate_domain_name}:443" : null
}
output "manual_dns_record" {
  description = "Manual DNS Record"
  value       = var.https_ssl_certificate != "none" ? "Please create DNS A record for Stream Manager 2.0: '${var.https_ssl_certificate_domain_name} - ${local.cluster_or_autoscale ? local.stream_manager_ip : local.standalone_elastic_ip}'" : ""
}
output "standalone_red5pro_server_brew_mixer_controller_page_url" {
  description = "standalone Red5 Pro Server Brew Mixer Controller Page URL"
  value       = local.standalone && var.standalone_red5pro_brew_mixer_enable ? var.https_ssl_certificate == "none" ? "http://${local.standalone_elastic_ip}:5080/brewmixer/rtController.html" : "https://${var.https_ssl_certificate_domain_name}/brewmixer/rtController.html" : null
}