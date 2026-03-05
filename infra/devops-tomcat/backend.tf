terraform {
  backend "s3" {
    bucket = "aifinops-dev"
    key    = "mom-tomcat-terraform.tfstate"
    region = "ap-south-2"
  }
}
