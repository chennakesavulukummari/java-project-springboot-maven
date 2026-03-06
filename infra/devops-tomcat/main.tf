# Security Group
resource "aws_security_group" "tomcat_test_sg" {
  name        = "tomcat-test-sg"
  description = "Allow SSH, HTTP and Tomcat"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["49.43.229.100/32"]
  }

  ingress {
    description = "Tomcat"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "tomcat-security-group"
    Environment  = var.environment
    Project_Name = var.project_name
    Created_By   = var.Created_By
  }
}

# IAM Role for EC2
resource "aws_iam_role" "tomcat_role" {
  name = "tomcat-test-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name         = "tomcat-test-iam-role"
    Environment  = var.environment
    Project_Name = var.project_name
    Created_By   = var.Created_By
  }
}

# IAM Role Policy Attachment - EC2 Access
resource "aws_iam_role_policy_attachment" "tomcat_role_attachment" {
  role       = aws_iam_role.tomcat_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# IAM S3 Access Policy
resource "aws_iam_role_policy_attachment" "tomcat_s3_access" {
  role       = aws_iam_role.tomcat_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# IAM SSM Access Policy
resource "aws_iam_role_policy_attachment" "tomcat_ssm_access" {
  role       = aws_iam_role.tomcat_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "tomcat_instance_profile" {
  name = "tomcat-test-instance-profile"
  role = aws_iam_role.tomcat_role.name

  tags = {
    Name         = "tomcat-test-instance-profile"
    Environment  = var.environment
    Project_Name = var.project_name
    Created_By   = var.Created_By
  }
}

# EC2 Instance
resource "aws_instance" "tomcat" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.tomcat_test_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.tomcat_instance_profile.name
  user_data              = file("user-data.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name         = var.name
    Environment  = var.environment
    Project_Name = var.project_name
    Created_By   = var.Created_By
  }
}
