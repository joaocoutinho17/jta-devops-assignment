# Architecture Proposal - jta-web.com

![Architecture Diagram](jta-solution-diagram.png)

The solution follows a **private-by-default** approach using Azure PaaS services. All resources are deployed in **West Europe** and are only accessible via corporate network or VPN.

For this assignment, I chose a flat Terraform structure instead of modules. Since the goal was to demonstrate the proposed infrastructure for the challenge and the resource set is relatively small, using modules would add unnecessary complexity.

## How to run

### 1. Authenticate with Azure

### 2. Initialise Terraform

```bash
terraform init -backend-config=environments/dev/backend.tfbackend
```

### 3. Plan

Review what Terraform will create before applying:

```bash
export TF_VAR_sql_admin_password="<password>"
terraform plan \
  -var-file="environments/dev/dev.tfvars"
```

### 4. Apply

```bash
export TF_VAR_sql_admin_password="<password>"
terraform apply \
  -var-file="environments/dev/terraform.tfvars"
```