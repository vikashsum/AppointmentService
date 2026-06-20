variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_access_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "aws_shared_credentials_file" {
  type    = string
  default = ""
}

variable "aws_profile" {
  type    = string
  default = ""
}

variable "ec2_key_name" {
  type    = string
  default = ""
}
