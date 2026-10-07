output "jenkins_server_ip" {
  description = "IP pública del servidor EC2 donde corre Jenkins"
  value       = aws_instance.jenkins_server.public_ip
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3 para artefactos"
  value       = aws_s3_bucket.jenkins_artifacts.id
}

output "ssh_connection_command" {
  description = "Comando directo para conectarse por SSH"
  value       = "ssh -i jenkins-key.pem ubuntu@${aws_instance.jenkins_server.public_ip}"
}