# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN S3 BUCKET AND DYNAMODB TABLE TO USE AS A TERRAFORM BACKEND
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# This module is forked from https://github.com/gruntwork-io/intro-to-terraform/tree/master/s3-backend
# ----------------------------------------------------------------------------------------------------------------------

terraform {
   backend "s3" {
     bucket         = "my-first-tfstate" #  YOUR BUCKET NAME
     key            = "remote_state/import-bootstrap/terraform.tfstate"
     region         = "us-east-1"
     dynamodb_table = "terraform-state-locking"
     encrypt        = true
   }
required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = "us-east-1"
}

# ------------------------------------------------------------------------------
# CREATE THE S3 BUCKET
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "my-first-tfstate" # YOUR BUCKET NAME
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket        = aws_s3_bucket.terraform_state.bucket 
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
# ------------------------------------------------------------------------------
# CREATE THE DYNAMODB TABLE
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
