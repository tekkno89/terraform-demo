
provider "aws" {
  region = "us-west-2"
  profile = "${var.aws_profile}"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "terraform-demo"
  cidr = "10.200.0.0/16"

  azs = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24"]
  public_subnets = ["10.200.11.0/24", "10.200.12.0/24", "10.200.13.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

resource "aws_instance" "nginx" {
  ami = "${var.ami_id}"
  instance_type = "t2.micro"

  subnet_id = "${module.vpc.private_subnets[0]}"
  security_groups = ["${aws_security_group.nginx.id}"]
}

module "nginx_elb" {
  source = "terraform-aws-modules/elb/aws"

  name = "terraform-demo-nginx"
  subnets = "${module.vpc.public_subnets}"
  security_groups = ["${aws_security_group.web.id}"]
  internal = false

  number_of_instances = 1
  instances = ["${aws_instance.nginx.id}"]

  listener = [
    {
      instance_port = "80"
      instance_protocol = "HTTP"
      lb_port = "80"
      lb_protocol = "HTTP"
    }
  ]

  health_check = [
    {
      target = "HTTP:80/"
      interval = 45
      healthy_threshold = 2
      unhealthy_threshold = 5
      timeout = 15
    }
  ]

}

resource "aws_security_group" "nginx" {
  name = "terrform-demo-internal"
  description = "Allow access from all internal network"

  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["${module.vpc.vpc_cidr_block}"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web" {
  name = "terraform-demo-web"
  description = "Allow all external web traffic"

  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

