output "vpc_id" {
  description = "VPC ID"
  value       = module.red5pro.vpc_id
}
output "vpc_name" {
  description = "VPC Name"
  value       = module.red5pro.vpc_name
}
output "ssh_private_key_path" {
  description = "SSH private key path"
  value       = module.red5pro.ssh_private_key_path
}
output "standalone_red5pro_server_ip" {
  description = "Red5 Pro Server IP"
  value       = module.red5pro.standalone_red5pro_server_ip
}
output "standalone_red5pro_server_http_url" {
  description = "Red5 Pro Server HTTP URL"
  value       = module.red5pro.standalone_red5pro_server_http_url
}
output "standalone_red5pro_server_https_url" {
  description = "Red5 Pro Server HTTPS URL"
  value       = module.red5pro.standalone_red5pro_server_https_url
}
