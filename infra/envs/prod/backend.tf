terraform {
  backend "s3" {
    bucket = "hello-today-state-bucket"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

