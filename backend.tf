terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "petclinic-tfstate-isi"
    key            = "prod/petclinic/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "petclinic-locks"
    encrypt        = true
  }
}