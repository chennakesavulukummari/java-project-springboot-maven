# Infrastructure - Terraform + Ansible

Provision EC2 instances on AWS using **Terraform** and configure them with **Ansible** roles for **Tomcat** and **MySQL**.

## Architecture

```
VPC: vpc-0305c51d2febe0d64
│
├── App Subnet: subnet-0ab7ef12823c1b8c3
│   └── EC2 (Tomcat App Server)
│       ├── Amazon Linux 2023
│       ├── Java 17 (Corretto)
│       └── Apache Tomcat 10.1
│
└── DB Private Subnet: subnet-01d078b173a769177
    └── EC2 (MySQL DB Server)
        ├── Amazon Linux 2023
        └── MySQL 8.0
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) >= 2.14
- AWS CLI configured with proper credentials
- SSH key pair for EC2 access

## Directory Structure

```
infra/
├── terraform/
│   ├── provider.tf          # AWS provider & backend
│   ├── variables.tf         # Input variables
│   ├── main.tf              # EC2 instances (Tomcat + MySQL)
│   ├── outputs.tf           # Instance IPs, IDs
│   └── terraform.tfvars     # Variable values (update this!)
│
└── ansible/
    ├── ansible.cfg           # Ansible configuration
    ├── inventory/
    │   └── hosts.ini         # Target hosts (update after terraform apply)
    ├── playbooks/
    │   ├── tomcat.yml        # Tomcat-only playbook
    │   ├── mysql.yml         # MySQL-only playbook
    │   └── site.yml          # Full stack playbook
    └── roles/
        ├── tomcat/
        │   ├── defaults/main.yml
        │   ├── tasks/main.yml
        │   ├── handlers/main.yml
        │   └── templates/
        │       ├── tomcat.service.j2
        │       ├── tomcat-users.xml.j2
        │       └── manager-context.xml.j2
        └── mysql/
            ├── defaults/main.yml
            ├── tasks/main.yml
            ├── handlers/main.yml
            └── templates/
                └── my.cnf.j2
```

---

## Step 1: Update Configuration

### Terraform (`infra/terraform/terraform.tfvars`)

Update the following values:

```hcl
key_pair_name          = "your-keypair-name"
app_security_group_ids = ["sg-xxxxxxxxxxxxxxxxx"]
db_security_group_ids  = ["sg-xxxxxxxxxxxxxxxxx"]
iam_instance_profile   = "your-instance-profile-name"
```

### Ansible (`infra/ansible/ansible.cfg`)

Update the SSH key path:

```ini
private_key_file = ~/.ssh/your-keypair.pem
```

---

## Step 2: Provision EC2 Instances (Terraform)

```bash
cd infra/terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (create EC2 instances)
terraform apply

# Note the output IPs
terraform output
```

---

## Step 3: Update Ansible Inventory

Copy the IPs from Terraform output into `infra/ansible/inventory/hosts.ini`:

```ini
[tomcat_servers]
<tomcat-private-ip> ansible_user=ec2-user

[mysql_servers]
<mysql-private-ip> ansible_user=ec2-user
```

Or use the auto-generated inventory:

```bash
terraform output -raw ansible_inventory > ../ansible/inventory/hosts.ini
```

---

## Step 4: Configure Servers (Ansible)

```bash
cd infra/ansible

# Test connectivity
ansible all -m ping

# Install full stack (MySQL first, then Tomcat)
ansible-playbook playbooks/site.yml

# Or install individually:
ansible-playbook playbooks/mysql.yml
ansible-playbook playbooks/tomcat.yml
```

---

## Step 5: Deploy Application

After Tomcat and MySQL are running, deploy your Spring Boot WAR:

```bash
# Build WAR
cd /path/to/java-project-springboot-maven
mvn clean package

# Copy WAR to Tomcat server
scp -i ~/.ssh/your-keypair.pem \
  target/c3ops-springboot-mysql-app-0.0.1-SNAPSHOT.jar \
  ec2-user@<tomcat-ip>:/opt/tomcat/latest/webapps/
```

Update `application.properties` on the Tomcat server to point to the MySQL server:

```properties
spring.datasource.url=jdbc:mysql://<mysql-private-ip>:3306/springboot_db
spring.datasource.username=appuser
spring.datasource.password=AppUser@123
```

---

## Teardown

```bash
cd infra/terraform
terraform destroy
```

---

## Default Credentials

| Service | User | Password |
|---------|------|----------|
| Tomcat Manager | admin | admin@123 |
| MySQL root | root | Root@123 |
| MySQL app user | appuser | AppUser@123 |

> ⚠️ **Change all default passwords before using in production!**
