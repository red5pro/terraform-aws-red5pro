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
output "red5pro_server_ip" {
    description = "Red5 Pro Server IP"
    value = module.red5pro.single_red5pro_server_ip
}
output "red5pro_server_http_url" {
    description = "Red5 Pro Server HTTP URL"
    value = module.red5pro.single_red5pro_server_http_url
}
output "red5pro_server_https_url" {
    description = "Red5 Pro Server HTTPS URL"
    value = module.red5pro.single_red5pro_server_https_url
}
output "red5pro_server_brew_mixer_controller_page_url" {
  description = "Red5 Pro Server Brew Mixer Controller Page URL"
  value = module.red5pro.single_red5pro_server_brew_mixer_controller_page_url
}