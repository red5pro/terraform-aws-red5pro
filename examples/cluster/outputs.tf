output "ssh_key_name" {
  description = "SSH key name"
  value       = module.red5pro.ssh_key_name
}
output "ssh_private_key_path" {
  description = "SSH private key path"
  value       = module.red5pro.ssh_private_key_path
}
output "vpc_id" {
  description = "VPC ID"
  value       = module.red5pro.vpc_id
}
output "vpc_name" {
  description = "VPC Name"
  value       = module.red5pro.vpc_name
}
output "subnet_ids" {
  description = "Subnets IDs"
  value       = module.red5pro.subnet_ids
}
output "stream_manager_ip" {
  description = "Stream Manager 2.0 Public IP or Load Balancer Public IP"
  value       = module.red5pro.stream_manager_ip
}
output "stream_manager_url_http" {
  description = "Stream Manager HTTP URL"
  value       = module.red5pro.stream_manager_url_http
}
output "stream_manager_url_https" {
  description = "Stream Manager HTTPS URL"
  value       = module.red5pro.stream_manager_url_https
}
output "stream_manager_red5pro_node_image" {
  description = "Stream Manager 2.0 Red5 Pro Node Image (AWS AMI)"
  value       = module.red5pro.stream_manager_red5pro_node_image
}
output "manual_dns_record" {
  description = "Manual DNS Record"
  value       = module.red5pro.manual_dns_record
}
