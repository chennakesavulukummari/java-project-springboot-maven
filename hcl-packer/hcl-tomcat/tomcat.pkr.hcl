packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_aws_account_id" {
  type    = string
  default = "225989338000"
}

variable "application_name" {
  type    = string
  default = "cloudbinary"
}

variable "application_version" {
  type    = string
  default = "1.0.0"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

# variable "packer_profile" {
#   type    = string
#   default = "packer-ec2-s3"
# }

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami" {
  type    = string
  default = "ami-0ec10929233384c7f"
}

# could not parse template for following block: "template: hcl2_upgrade:2: bad character U+0060 '`'"

source "amazon-ebs" "ubuntu" {
  ami_name                    = "tomcloudbinary"
  associate_public_ip_address = "true"
  force_delete_snapshot       = "true"
  force_deregister            = "true"

  instance_type = var.instance_type
  profile       = "cf36"
  region        = var.region
  source_ami    = var.source_ami
  ssh_username  = "ubuntu"
  tags = {
    CreatedBy = "Packer"
    Name      = "tom"
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = ["sudo apt-get update",
      "sudo apt-get install software-properties-common -y"
    ]
  }

  provisioner "shell" {
    inline = ["sudo add-apt-repository --yes --update ppa:ansible/ansible", "sudo apt-get install ansible -y"]
  }

  provisioner "shell" {
    inline = ["sudo apt-get install git -y"]
  }

  provisioner "shell" {
    inline = ["sudo apt-get install curl -y"]
  }

  provisioner "shell" {
    inline = ["sudo apt-get install wget -y"]
  }

  provisioner "shell" {
    inline = ["sudo apt-get update", "sudo apt-get install zip -y"]
  }

  #   provisioner "shell" {
  #     execute_command = "sudo -u root /bin/bash -c '{{ .Path }}'"
  #     scripts         = ["awscli.sh"]
  #   }

  #   provisioner "ansible-local" {
  #     extra_arguments = ["-vvvv"]
  #     playbook_file   = "./tomcat-install.yml"
  #   }

  #   provisioner "shell" {
  #     inline = ["sudo aws s3 cp s3://codewithck.com/devops.war /opt/tomcat/webapps/"]
  #   }
}
