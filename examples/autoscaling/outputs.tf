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
  sensitive   = true
}
output "ssh_private_key_path" {
  description = "SSH private key path"
  value       = module.red5pro.ssh_private_key_path
}


