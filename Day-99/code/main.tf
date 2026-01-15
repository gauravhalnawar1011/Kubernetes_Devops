data "aws_vpc" "main_vpc" {
  filter {
    name = "tag:Name"
    values = ["default"]
     }
}

data "aws_subnet" "shared" {
  filter {
    name = "tag:Name"
    values = ["subnetA"]
  }
  vpc_id = data.aws_vpc.main_vpc.id
}


data "aws_ami" "linux2" {
  owners = ["amazon"]
  most_recent = true

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name= "virtualization-type"
    values = ["hvm"]
  }
}
resource "aws_instance" "main" {
  ami = data.aws_ami.linux2.id
  instance_type = "t2.micro"
  subnet_id = data.aws_vpc.main_vpc.id

}