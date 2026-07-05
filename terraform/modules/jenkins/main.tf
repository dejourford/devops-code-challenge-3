# Jenkins Security Group
resource "aws_security_group" "jenkins" {
  name        = "${var.project}-${var.environment}-jenkins-sg"
  description = "Security group for Jenkins EC2 host"
  vpc_id      = var.vpc_id

  ingress {
    description = "Jenkins web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-jenkins-sg"
  }
}

# Jenkins IAM Role
resource "aws_iam_role" "jenkins" {
  name = "${var.project}-${var.environment}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project}-${var.environment}-jenkins-role"
  }
}

# ECR Push permissions
resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# SSM access
resource "aws_iam_role_policy_attachment" "jenkins_ssm" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project}-${var.environment}-jenkins-instance-profile"
  role = aws_iam_role.jenkins.name
}

# Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# EC2 Instance
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io unzip curl screen
              systemctl start docker
              systemctl enable docker
              chmod 666 /var/run/docker.sock

              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
              unzip /tmp/awscliv2.zip -d /tmp
              /tmp/aws/install
              rm -rf /tmp/awscliv2.zip /tmp/aws

              cat > /root/Dockerfile << 'DOCKERFILE'
              FROM jenkins/jenkins:lts
              USER root
              RUN apt-get update && apt-get install -y docker.io unzip curl && \
                  usermod -aG docker jenkins && \
                  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
                  unzip /tmp/awscliv2.zip -d /tmp && \
                  /tmp/aws/install && \
                  rm -rf /tmp/awscliv2.zip /tmp/aws
              USER jenkins
              DOCKERFILE

              docker build -t jenkins-custom:latest /root/
              screen -dmS jenkins docker run \
                --name jenkins \
                --restart always \
                -p 8080:8080 -p 50000:50000 \
                -v jenkins_home:/var/jenkins_home \
                -v /var/run/docker.sock:/var/run/docker.sock \
                jenkins-custom:latest
              EOF

  tags = {
    Name = "${var.project}-${var.environment}-jenkins-ec2"
  }
}