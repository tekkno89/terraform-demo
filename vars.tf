
variable "aws_profile" {
  type = "string"
  description = "Profile that your AWS provider will use to create resources"
}

variable "ami_id" {
  type = "string"
  description = "AMI ID for EC2 instance"
}