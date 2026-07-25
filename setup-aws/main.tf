terraform {
  backend "s3" {
    bucket         = "petclinic-tfstate-isi"  # Modifié ici !
    key            = "setup-aws/terraform.tfstate"
    region         = "us-east-1"
    # dynamodb_table = "petclinic-tf-locks"   <-- Commente cette ligne si la table DynamoDB n'est pas encore créée
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  skip_credentials_validation = true
  skip_requesting_account_id  = false
}

data "aws_s3_bucket" "tf_state" {
  bucket = "petclinic-tfstate-isi"  # Modifié ici aussi !
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = "petclinic-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_name" {
  value = data.aws_s3_bucket.tf_state.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.tf_locks.id
}