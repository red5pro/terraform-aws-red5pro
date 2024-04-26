####################################################################################
# Create new VPC using red5pro module
####################################################################################

provider "aws" {
  region     = "us-west-1" # AWS region
  access_key = ""          # AWS IAM Access key
  secret_key = ""          # AWS IAM Secret key
}

module "red5pro_vpc" {
  source = "../../"

  type = "vpc"         # Deployment type: single, cluster, autoscaling, vpc
  name = "red5pro-vpc" # Name to be used on all the resources as identifier

  # VPC configuration
  vpc_create         = true # true - create new VPC, false - use existing VPC
  vpc_cidr_block     = "10.105.0.0/16"
  vpc_public_subnets = ["10.105.0.0/24", "10.105.1.0/24", "10.105.2.0/24", "10.105.3.0/24"] # Public subnets for Stream Manager and Red5 Pro server instances

  # Red5 Pro tags configuration - it will be added to all Red5 Pro resources
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "red5pro"
  }
}

