output "ecr_repository_url" {
  description = "URL du dépôt Amazon ECR"
  value       = aws_ecr_repository.petclinic_ecr.repository_url
}
