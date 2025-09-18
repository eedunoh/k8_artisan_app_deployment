# Create a security group for cicd tools

resource "aws_security_group" "cicd_sg" {
  name        = "cicd server security group"
  description = "Allow SSH and HTTP"

  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "cicd server ingress"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]    # we can modify this rule to allow traffic from ONLY authorized IP addresses to achieve stricter security.
  }

  ingress {
    description = "cicd server ingress"
    from_port   = 9001
    to_port     = 9001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]    # we can modify this rule to allow traffic from ONLY authorized IP addresses to achieve stricter security.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




# setup an ec2 instance for the CiCd server
resource "aws_instance" "cicd_server" {
  ami                    = "ami-016038ae9cc8d9f51"          # Amazon Linux 2
  instance_type          = "t3.xlarge"                      # or whatever type you want
  key_name               = var.ec2_key_name                 # this is an already existing key on my aws account
  
  instance_initiated_shutdown_behavior = "terminate"

  associate_public_ip_address = true

  # To achieve stricter security, this can be deployed in the private subnet of the VPC. However, in this project, I will It deploy it in the public subnet of the newly created VPC.
  subnet_id = aws_subnet.public_subnet_1.id      
  
  vpc_security_group_ids = [aws_security_group.cicd_sg.id]
  
  availability_zone = "eu-north-1a"
  
  # IAM instance profile (needed for jenkins (cicd) access to s3)
  iam_instance_profile = aws_iam_instance_profile.cicd_profile.name
  
  user_data = base64encode(file("cicd_ec2_user_data.sh")) # Bootstrap script to install and run cicd tools

  tags = {
    Name = "cicd-Server"
  }
}



resource "aws_s3_bucket" "terraform_state" {
  bucket = "app-remote-state-bucket-fyi"
}