output "vpc_id" {
  description = "VPC ID"
  value       = module.red5pro.vpc_id
}
output "vpc_name" {
  description = "VPC Name"
  value       = module.red5pro.vpc_name
}
output "ssh_key_name" {
  description = "SSH key name"
  value       = module.red5pro.ssh_key_name
}
output "ssh_private_key_path" {
  description = "SSH private key path"
  value       = module.red5pro.ssh_private_key_path
}

output "load_balancer_dns_name" {
  description = "Load Balancer DNS Name"
  value       = module.red5pro.load_balancer_dns_name
}
output "load_balancer_http_url" {
  description = "Load Balancer HTTP URL"
  value       = module.red5pro.load_balancer_http_url
}
output "load_balancer_https_url" {
  description = "Load Balancer HTTPS URL"
  value       = module.red5pro.load_balancer_https_url
}
output "node_image_name" {
  description = "AMI image name of the Red5 Pro Node Origin image"
  value       = module.red5pro.node_image_name
}
