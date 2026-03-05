terraform {
  backend "s3" {
    bucket = "aifinops-dev"
    key    = "mom-tomcat-test-terraform.tfstate"
    region = "ap-south-2"
  }
}
