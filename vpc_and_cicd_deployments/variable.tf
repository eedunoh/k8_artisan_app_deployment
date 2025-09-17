variable "region" {
  default = "eu-north-1"
  description = "aws region"
  type = string
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
    description = "vpc cidr block"
    type = string
}

variable "vpc_name" {
    default = "artisian_app_vpc"
    description = "aws vpc name"
    type = string
}

variable "jenkins_sg_name" {
    default = "jenkins-sg"
    description = "jenkins security group name"
    type = string
}

variable "sonarqube_sg_name" {
    default = "sonarqube-sg"
    description = "sonarqube security group name"
    type = string
}

variable "ec2_key_name" {
    default = "webapp1key"
    description = "ec2 key name"
    type = string
}

