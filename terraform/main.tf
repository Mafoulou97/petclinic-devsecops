terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variable définissant l'image Docker Hub
variable "docker_image" {
  description = "Image Docker hébergée sur Docker Hub"
  type        = string
  default     = "mafoulou97/spring-petclinic:v1"
}
