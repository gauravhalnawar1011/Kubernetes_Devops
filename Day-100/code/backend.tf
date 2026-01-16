terraform {
  backend "s3" {
    bucket = "space9-terraform-bucket-v1"
    key    = "www/terraform.tfstate"
    region = "ap-south-1"
  }
}