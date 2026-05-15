# C3Ops :
    1. C3Ops Website
    2. C3Ops CRM
    3. C3Ops LMS
    4. C3Ops FinOps
    5. Cloud Binary Website
    6. Cloud Binary LMS 
# Create 3 Tier Architecture 
    Application : Cloud Binary 
# Step-1 : AWS Account
    preprod : ap-south-2  
    prod : ap-south-2 
# Step-2 : Region
    Primary   : ap-south-2
    Secondary : ap-south-1 
# Step-3 : IAM Svc-user
    Permissions: 
# Step-4 : Terraform Version
    Latest Version: 1.9.0 
# Step-5 : DevOps - CI/CD : Jenkins/ AWS CodeBuild/ Azure Pipelines / GitHub Actions / GitLab CI
    AWS CodeBuild / AWS CodePipeline
# Step-6 : Do we have Core-infra?
    Landing Zone :
    Core-Infra   : preprod, and Prod 
Key Components: 
1. VPC
2. Public Subnets
3. Private Subnets Web & App
4. Private Subnets DB
5. IGW
6. NAT Gateway
7. Route Tables
8. NACL
9. Security Groups

# Step-7 : What kind of Application we are going to deploy?
    - Server     : Yes 
    - Serverless
    - Container
# Step-8 : Do we have Stages? If yes, how many?
    - Dev, Test : AWS : preprod
    - Prod      : AWS : prod
# Step-9 : Download, Install, Configure Terraform on Any OS | How to create .tf files and write code

# Task: 

GitHub: Repos 
   1. Core-infra
    1. VPC
    2. Public Subnets
    3. Private Subnets Web & App
    4. Private Subnets DB
    5. IGW
    6. NAT Gateway
    7. Route Tables
    8. NACL
    9. Security Groups

   3. Application Infra
      1. infra/cloudbinary/dev / test / prod 