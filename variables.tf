variable "aws_region" {
  description = "AWS region to launch servers using Ipv6 and ipv4."
  default     = "us-east-1"
}

#Choosing the AZ's to use in the region
variable "azs" {
  description = "AZ Infomration"
  type = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]

}
variable "cidr" {
  description = "VPC IPv4 CIDR Block"
  default     = "10.0.0.0/16"
}

#Public IPv4 Subnet Space
variable "pubsubnets" {
  description = "IPv4 Public Subnet"
  type = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

#Private IPV4 subnet Space
variable "privsubnets" {
  description = "IPv4 Private Subnet"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

#Compute Variables
#Key to use
variable "key_name" {
  description = "Key to use on instaces"
  default     = "IPv6"
}

#Instance Type Selection, using the new Graviton 2 arm instance, for more on Graviton 2: https://aws.amazon.com/ec2/graviton/
variable "ipv6_instance_type" {
  description = "What instance size to use"
  default     = "t2.micro"
}
variable "ipv6_aws_amis" {
  default = {
    #Using ARM based ami to take advantage of Graviton 2
    "us-east-1" = "ami-02f3f602d23f1659d"
  }
}
