terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------------
# 1. GENERACIÓN AUTOMÁTICA DE CLAVE SSH (IaC)
# ------------------------------------------------------------------

# Genera un par de claves RSA en memoria
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Registra la clave publica en AWS EC2 Key Pairs
resource "aws_key_pair" "generated_key" {
  key_name   = "jenkins-ec2-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Guarda la clave privada localmente (.pem) para poder conectarte por SSH
resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/jenkins-key.pem"
  file_permission = "0600"
}

# ------------------------------------------------------------------
# 2. BUCKET S3 PARA ARTEFACTOS / ESTADO (IaC)
# ------------------------------------------------------------------

resource "aws_s3_bucket" "jenkins_artifacts" {
  bucket        = var.s3_bucket_name
  force_destroy = true

  tags = {
    Name        = "Jenkins-Artifacts-Bucket"
    Environment = "Dev"
  }
}

# ------------------------------------------------------------------
# 3. GRUPO DE SEGURIDAD (Firewall)
# ------------------------------------------------------------------

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-server-sg"
  description = "Permitir SSH (22) y puerto de Jenkins (8080)"

  # SSH
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins UI
  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tráfico saliente sin restricciones
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------
# 4. INSTANCIA EC2 CON DOCKER Y DOCKER COMPOSE
# ------------------------------------------------------------------

resource "aws_instance" "jenkins_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated_key.key_name # Usa la llave generada dinámicamente

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y ca-certificates curl gnupg lsb-release

              # Instalación de Docker
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              # Iniciar y habilitar servicio
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "Jenkins-Server-IaC"
  }
}