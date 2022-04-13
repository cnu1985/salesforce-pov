

data "aws_ami" "ami" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*"]
  }
}


# resource "aws_key_pair" "test-tgw-keypair" {
#   key_name   = "test-tgw-keypair"
#   public_key = "${var.public_key}"
# }

resource "tls_private_key" "keypair_material" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "keypair" {
  key_name   = var.keypair
  public_key = tls_private_key.keypair_material.public_key_openssh
}




resource "aws_security_group" "sec-group-vpc-1-ssh-icmp" {
  name        = "sec-group-vpc-1-ssh-icmp"
  description = "test-tgw: Allow SSH and ICMP traffic"
  vpc_id      = aws_vpc.vpc-1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8 # the ICMP type number for 'Echo'
    to_port     = 0 # the ICMP code
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0 # the ICMP type number for 'Echo Reply'
    to_port     = 0 # the ICMP code
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "sec-group-vpc-1-ssh-icmp"
    scenario = "${var.scenario}"
  }
}

resource "aws_network_interface" "nic" {
  subnet_id       = "${aws_subnet.vpc-1-sub-a.id}"
  security_groups = [aws_security_group.sec-group-vpc-1-ssh-icmp.id]
  private_ips     = var.private_ip == null ? null : [var.private_ip]
  tags = {
    Name = "${var.name}-nic"
  }
}

resource "aws_instance" "test-tgw-instance1-dev" {
  ami                         = "${data.aws_ami.ami.image_id}"
  instance_type               = "t2.micro"
  key_name                    = "tgwkey"
  network_interface {
  network_interface_id = aws_network_interface.nic.id
  device_index         = 0
}

  tags = {
    Name = "test-tgw-instance1-dev"
    scenario    = "${var.scenario}"
    env         = "dev"
    az          = "${var.az1}"
    vpc         = "1"
  }
}

resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = "${var.name}-eip"
  }
}

resource "aws_eip_association" "eip-association" {
  network_interface_id = aws_network_interface.nic.id
  allocation_id        = aws_eip.eip.id
  depends_on = [
    aws_instance.test-tgw-instance1-dev
  ]
}