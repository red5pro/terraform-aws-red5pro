
################################################################################
# OUTPUTS
################################################################################

# output "stream_manager_ip" {
#   value = local.stream_manager_ip
# }

output "node_origin_image" {
  value = var.origin_node_image ? aws_ami_from_instance.red5pro_node_origin_image[0].name : null
}
output "node_edge_image" {
  value = var.edge_node_image ? aws_ami_from_instance.red5pro_node_edge_image[0].name : null
}
output "node_transcoder_image" {
  value = var.transcoder_node_image ? aws_ami_from_instance.red5pro_node_transcoder_image[0].name : null
}
output "node_relay_image" {
  value = var.relay_node_image ? aws_ami_from_instance.red5pro_node_relay_image[0].name : null
}


output "single" {
  value = local.single
}
output "cluster" {
  value = local.cluster
}
output "autoscaling" {
  value = local.autoscaling
}
output "ssh_key_name" {
  value = local.ssh_key_name
}
output "vpc_id" {
  value = local.vpc_id
}
output "vpc_name" {
  value = local.vpc_name
}
output "subnet_ids" {
  value = local.subnet_ids
}
output "elastic_ip" {
  value = local.elastic_ip
}
output "mysql_create" {
  value = local.mysql_create
}
output "mysql_host" {
  value = local.mysql_host
}
output "mysql_local_enable" {
  value = local.mysql_local_enable
}
output "stream_manager_ip" {
  value = local.stream_manager_ip
}

output "ssh_private_key_path" {
  value = local.ssh_private_key_path
}

output "https_domain_name" {
  value = var.https_letsencrypt_enable ? var.https_letsencrypt_certificate_domain_name : null
}

# output "ssh_key_name" {
#   value = local.ssh_key_name
# }
# output "ssh_private_key_path" {
#   value = local.ssh_private_key_path
# }
# output "vpc_id" {
#   value = local.vpc_id
# }
# output "vpc_name" {
#   value = local.vpc_name
# }
# output "subnet_ids" {
#   value = local.subnet_ids
# }
# output "elastic_ip" {
#   value = local.elastic_ip
# }
