# us-west-2

module "awstgw13" {
  source              = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version             = "1.1.0"
  cloud               = "AWS"
  name                = "awstgw13"
  region              = "us-west-2"
  cidr                = "10.13.0.0/16"
  account             = aviatrix_account.aws_transit_spoke.account_name
  enable_segmentation = true
}

module "prod1" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version         = "1.1.0"
  cloud           = "AWS"
  name            = "prod1"
  region          = "us-west-2"
  cidr            = "10.1.0.0/16"
  account         = aviatrix_account.aws_transit_spoke.account_name
  transit_gw      = module.awstgw13.transit_gateway.gw_name
  security_domain = aviatrix_segmentation_security_domain.prod.domain_name
  ha_gw           = false
}

resource "aviatrix_gateway" "egress" {
  cloud_type     = 1
  account_name   = aviatrix_account.aws_transit_spoke.account_name
  gw_name        = "egress"
  vpc_id         = module.prod1.vpc.vpc_id
  vpc_reg        = "us-west-2"
  gw_size        = "t2.micro"
  subnet         = module.prod1.vpc.public_subnets[0].cidr
  single_ip_snat = true
}

resource "aviatrix_fqdn" "egress_fqdn" {
  fqdn_tag            = "Egress Traffic"
  fqdn_enabled        = true
  fqdn_mode           = "white"
  manage_domain_names = false
  gw_filter_tag_list {
    gw_name = aviatrix_gateway.egress.gw_name
  }
}

resource "aviatrix_fqdn_tag_rule" "tag_rule" {
  fqdn_tag_name = aviatrix_fqdn.egress_fqdn.fqdn_tag
  fqdn          = "salesforce.com"
  protocol      = "tcp"
  port          = "443"
  action        = "Allow"
}

module "dev2" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version         = "1.1.0"
  cloud           = "AWS"
  name            = "dev2"
  region          = "us-west-2"
  cidr            = "10.2.0.0/16"
  account         = aviatrix_account.aws_transit_spoke.account_name
  transit_gw      = module.awstgw13.transit_gateway.gw_name
  security_domain = aviatrix_segmentation_security_domain.dev.domain_name
  ha_gw           = false
}

# us-east-1

module "awstgw14" {
  source                  = "terraform-aviatrix-modules/aws-transit-firenet/aviatrix"
  version                 = "5.0.0"
  name                    = "awstgw14"
  region                  = "us-east-1"
  account                 = aviatrix_account.aws_transit_spoke.account_name
  cidr                    = "10.14.0.0/16"
  firewall_image          = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
  prefix                  = false
  suffix                  = false
  bootstrap_bucket_name_1 = aws_s3_bucket.pan_bootstrap_s3.bucket
  iam_role_1              = var.ec2_role_name
  enable_segmentation     = true
  insane_mode             = true
}

module "prod3" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version         = "1.1.0"
  cloud           = "AWS"
  name            = "prod3"
  region          = "us-east-1"
  cidr            = "10.3.0.0/16"
  account         = aviatrix_account.aws_transit_spoke.account_name
  transit_gw      = module.awstgw14.transit_gateway.gw_name
  security_domain = aviatrix_segmentation_security_domain.prod.domain_name
}

module "dev4" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version         = "1.1.0"
  cloud           = "AWS"
  name            = "dev4"
  region          = "us-east-1"
  cidr            = "10.4.0.0/16"
  account         = aviatrix_account.aws_transit_spoke.account_name
  transit_gw      = module.awstgw14.transit_gateway.gw_name
  security_domain = aviatrix_segmentation_security_domain.dev.domain_name
  ha_gw           = false
}

module "tableau5" {
  source                           = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version                          = "1.1.0"
  cloud                            = "AWS"
  name                             = "tableau5"
  region                           = "us-east-1"
  cidr                             = "10.3.0.0/16"
  account                          = aviatrix_account.aws_ma.account_name
  transit_gw                       = module.awstgw14.transit_gateway.gw_name
  security_domain                  = aviatrix_segmentation_security_domain.tableau.domain_name
  ha_gw                            = false
  included_advertised_spoke_routes = "10.33.1.1/32,10.33.1.2/32"
}

module "tableau5_nat" {
  source          = "./modules/mc-overlap-nat-spoke"
  spoke_gw_object = module.tableau5.spoke_gateway
  spoke_cidrs     = [module.tableau5.vpc.cidr]
  transit_gw_name = module.awstgw14.transit_gateway.gw_name
  gw1_snat_addr   = "10.33.1.1"
  gw2_snat_addr   = "10.33.1.2"
  depends_on = [
    module.tableau5,
    module.awstgw14
  ]
}