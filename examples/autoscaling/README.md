# AWS Red5 Pro Stream Manager cluster with autoscaling Stream Managers

This example illustrates how to create Red5 Pro deployment in AWS with Autoscaling Stream Managers (MySQL RDS + Load Balancer + Autoscaling Stream Managers + Autoscaling Node group with Origin, Edge, Transcoder, Relay instances)

* VPC create or use existing
* Security groups will be created automatically (Stream Managers, Nodes, MySQL DB)
* SSH key create or use existing
* MySQL DB will be created automaticaly in RDS
* SSL certificate use existing in AWS Certificate Manager or use Load Balancer without SSL certificate (HTTP only) - it can be useful with Cloudflare
* Load Balancer for Stream Managers will be created automatically
* Autoscaling group for Stream Managers will be created automatically
* Stream Manager image will be created automatically
* Launch configuration for Stream Managers will be created automatically
* Target group for Stream Managers will be created automatically
* Origin node image create or not (it is optional)
* Edge node image create or not (it is optional)
* Transcoder node image create or not (it is optional)
* Relay node image create or not (it is optional)
* Autoscaling node group using API to Stream Manager (optional) - (https://www.red5pro.com/docs/special/concepts/nodegroup/)

Red5 Pro documentation for AWS deployemnt: https://www.red5pro.com/docs/installation/auto-aws/overview/  
Red5 Pro documentation for AWS Autoscaling Stream Managers: https://www.red5pro.com/docs/installation/auto-aws/recommended-use-aws-autoscaling/

## Preparation

* Install **terraform** https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
* Install **AWS CLI** https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
* Install **jq** Linux or Mac OS only - `apt install jq` or `brew install jq` (It is using in bash scripts to create/delete Stream Manager node group using API)
* Download Red5 Pro server build: (Example: red5pro-server-0.0.0.b0-release.zip) https://account.red5pro.com/downloads
* Download Red5 Pro Autoscale controller for AWS: (Example: aws-cloud-controller-0.0.0.jar) https://account.red5pro.com/downloads
* Get Red5 Pro License key: (Example: 1111-2222-3333-4444) https://account.red5pro.com
* Get AWS Access key and AWS Secret key or use existing (AWS IAM - EC2 full access, RDS full access, VPC full access, Certificate manager read only)
* Copy Red5 Pro server build and Red5 Pro Autoscale controller for AWS to the root folder of your project

Example:  

```bash
cp ~/Downloads/red5pro-server-0.0.0.b0-release.zip ./
cp ~/Downloads/aws-cloud-controller-0.0.0.jar ./
```

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

## Notes

* To activate HTTPS/SSL on the Stream Managers Load Balancer you need to add DNS CNAME record for Load Balancer DNS name
* Note that this example may create resources which can cost money. Run `terraform destroy` when you don't need these resources.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_red5pro"></a> [red5pro](#module\_red5pro) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_load_balancer_dns_name"></a> [load\_balancer\_dns\_name](#output\_load\_balancer\_dns\_name) | Load Balancer DNS Name |
| <a name="output_load_balancer_http_url"></a> [load\_balancer\_http\_url](#output\_load\_balancer\_http\_url) | Load Balancer HTTP URL |
| <a name="output_load_balancer_https_url"></a> [load\_balancer\_https\_url](#output\_load\_balancer\_https\_url) | Load Balancer HTTPS URL |
| <a name="output_module_output"></a> [module\_output](#output\_module\_output) | n/a |
| <a name="output_mysql_host"></a> [mysql\_host](#output\_mysql\_host) | MySQL host |
| <a name="output_node_origin_image"></a> [node\_origin\_image](#output\_node\_origin\_image) | AMI image name of the Red5 Pro Node Origin image |
| <a name="output_ssh_key_name"></a> [ssh\_key\_name](#output\_ssh\_key\_name) | SSH key name |
| <a name="output_ssh_private_key_path"></a> [ssh\_private\_key\_path](#output\_ssh\_private\_key\_path) | SSH private key path |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | VPC Name |
