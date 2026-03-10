terraform {
  backend "s3" {
    bucket = "aifinops-dev"
    key    = "mom-docker-terraform.tfstate"
    region = "ap-south-2"
  }
}
