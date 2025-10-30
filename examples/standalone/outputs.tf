output "ssh_key_name" {
  description = "SSH key name"
  value = module.red5pro.ssh_key_name
}
output "ssh_private_key_path" {
  description = "SSH private key path"
  value = module.red5pro.ssh_private_key_path
}
output "vpc_id" {
  description = "VPC ID"
  value = module.red5pro.vpc_id
}
output "vpc_name" {
  description = "VPC Name"
  value = module.red5pro.vpc_name
}
output "subnet_ids" {
  description = "Subnets IDs"
  value = module.red5pro.subnet_ids
}
output "standalone_red5pro_server_ip" {
  description = "Standalone Red5 Pro Server IP"
  value = module.red5pro.standalone_red5pro_server_ip
}
output "standalone_red5pro_server_http_url" {
  description = "Standalone Red5 Pro Server HTTP URL"
  value = module.red5pro.standalone_red5pro_server_http_url
}
output "standalone_red5pro_server_https_url" {
  description = "Standalone Red5 Pro Server HTTPS URL"
  value = module.red5pro.standalone_red5pro_server_https_url
}
output "manual_dns_record" {
  description = "Manual DNS Record"
  value       = module.red5pro.manual_dns_record
}
output "standalone_red5pro_server_brew_mixer_controller_page_url" {
  description = "Standalone Red5 Pro Server Brew Mixer Controller Page URL"
  value       = module.red5pro.standalone_red5pro_server_brew_mixer_controller_page_url
}
output "security_group_name_standalone" {
  description = "Security group name Standalone Red5 Pro server"
  value       = module.red5pro.security_group_name_standalone
}
