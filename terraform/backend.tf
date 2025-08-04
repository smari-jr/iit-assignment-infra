terraform {
  backend "s3" {
    bucket         = "iit-test-bucket-assignment"
    key            = "terraform/dev/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}