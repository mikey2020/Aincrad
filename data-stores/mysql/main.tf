provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket = "sm-ascentregtech-terraform"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "sm-ascentregtech-terraform-table"
    encrypt = true
  }
}

resource "aws_db_instance" "example" {
  identifier_prefix = var.db_identifier_prefix
  engine = "mysql"
  allocated_storage = "10"
  instance_class = "db.t2.micro"
  name = var.db_name
  username = var.db_username
  password = var.db_password
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key = var.db_remote_state_key
    region = "us-east-2"
  }
}

