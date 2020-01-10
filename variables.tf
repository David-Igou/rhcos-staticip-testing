variable "server_image_id" {
  type        = string
  default     = "ami-0bc59aaa7363b805d"
  description = "RHCOS image. Default is what is currently used for 4.2 IPI"
}

variable "server_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "vpc_cidr" {
  default     = "10.5.0.0/16"
  type        = string
  description = "VPC CIDR"

}

variable "vpc_subnet" {
  default     = "10.5.1.0/24"
  type        = string
  description = "VPC Subnet"
}


