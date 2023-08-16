output "vpc_id" {
    description = "VPC ID"
    value = module.red5pro.vpc_id
}
output "vpc_name" {
    description = "VPC Name"
    value = module.red5pro.vpc_name
}
output "ssh_key_name" {
  description = "SSH key name"
  value = module.red5pro.ssh_key_name
}
output "ssh_private_key_path" {
  description = "SSH private key path"
  value = module.red5pro.ssh_private_key_path
}
output "mysql_host" {
  description = "MySQL host"
  value = module.red5pro.mysql_host
}
output "stream_manager_ip" {
  description = "Stream Manager IP"
  value = module.red5pro.stream_manager_ip
}
output "stream_manager_http_url" {
  description = "Stream Manager HTTP URL"
  value = module.red5pro.stream_manager_http_url
}
output "stream_manager_https_url" {
  description = "Stream Manager HTTPS URL"
  value = module.red5pro.stream_manager_https_url
}
output "node_origin_image" {
  description = "AMI image name of the Red5 Pro Node Origin image"
  value = module.red5pro.node_origin_image
}
