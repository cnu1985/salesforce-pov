provider "aws" {
  region = "us-west-1"
}

module "aviatrix-iam-roles" {
  source = "github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-iam-roles?ref=terraform_0.14"
}

module "aviatrix-controller-build" {
  source                 = "./modules/aviatrix-controller-build"
  vpc                    = aws_vpc.vpc.id
  subnet                 = aws_subnet.subnet.id
  keypair                = "us-west-1"
  ec2role                = module.aviatrix-iam-roles.aviatrix-role-ec2-name
  incoming_ssl_cidr      = var.incoming_ssl_cidr
  type                   = "MeteredPlatinumCopilot"
  termination_protection = "false" # Set to true for production
}

module "aviatrix-controller-initialize" {
  source              = "github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-initialize?ref=terraform_0.14"
  admin_email         = var.admin_email
  admin_password      = var.admin_password
  private_ip          = module.aviatrix-controller-build.private_ip
  public_ip           = module.aviatrix-controller-build.public_ip
  access_account_name = var.access_account_name
  aws_account_id      = var.aws_account_id
  vpc_id              = aws_vpc.vpc.id
  subnet_id           = aws_subnet.subnet.id
}