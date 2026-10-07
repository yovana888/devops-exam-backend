variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Región de AWS donde se desplegarán los recursos"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Tipo de instancia EC2 compatible con Free Tier"
}

variable "ami_id" {
  type        = string
  default     = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS en us-east-1
  description = "AMI ID para el sistema operativo Ubuntu Server"
}

variable "s3_bucket_name" {
  type        = string
  default     = "devops-exam-jenkins-artifacts-unique-bucket"
  description = "Nombre único a nivel global para el bucket S3"
}