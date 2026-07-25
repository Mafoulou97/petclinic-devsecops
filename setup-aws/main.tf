terraform {
  backend "s3" {
    bucket  = "petclinic-tfstate-isi"
    key     = "setup-aws/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"

  skip_credentials_validation = true
  skip_requesting_account_id  = false
}

data "aws_s3_bucket" "tf_state" {
  bucket = "petclinic-tfstate-isi"
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