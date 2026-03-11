terraform {
  backend "s3" {
    bucket = "aifinops-dev"
    key    = "mom-ansible-terraform.tfstate"
    region = "ap-south-2"
  }
}
