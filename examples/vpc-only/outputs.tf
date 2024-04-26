output "vpc_id" {
  description = "VPC ID"
  value       = module.red5pro_vpc.vpc_id
}
output "vpc_name" {
  description = "VPC Name"
  value       = module.red5pro_vpc.vpc_name
}
output "subnet_ids" {
  description = "Subnet IDs"
  value       = module.red5pro_vpc.subnet_ids
}
