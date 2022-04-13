variable "access_key" {
  default = " "
}

variable "secret_key" {
  default = " "
}

variable "region" {
  default = "us-east-1"
}

variable "az1" {
  default = "us-east-1a"
}

variable "az2" {
  default = "us-east-1b"
}

variable "scenario" {
  default = "test-tgw"
}

variable "keypair" {
  default = "tgwkey"
}

variable "token" {
  default = " "
}

variable "name" {
  default = "mnainstance"
}

variable "private_ip" {
  type    = string
  default = null
}