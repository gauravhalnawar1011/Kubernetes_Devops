variable "project_name" {
  type        = string
  description = "Project or cluster name"
  default     = "my-prod-vpc"
}

variable "private_subnet_cidrs" {
  description = "this for the vpc private subnet cidr range"
  default = [
    "10.0.11.0/24",
    "10.0.12.0/24",
  "10.0.13.0/24"]
}

variable "public_subnet_cidrs" {
  description = "this for the vpc public subnet cidr range"
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}


variable "subnet-azs" {
  description = "this for the avilavlity zone for the subnet"
  default = [
    "ap-south-1a",
    "ap-south-1b",
    "ap-south-1c"
  ]
}


variable "vpc_cidr_range" {
    description = "this for the vpc cidr range"
    default = "10.0.0.0/16"
    
  
}

