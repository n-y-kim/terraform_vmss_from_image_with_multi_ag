# Azure VMSS Lifecycle Hook
This feature enables users to conduct a graceful shutdown on VMSS instance, when it is targeted for deletion. This provides huge flexibility for exceptional case handling on customer code.

## Overall Architecture
![Architecture Image](https://github.com/bedro96/terraform_vmss_ag/blob/master/vmss_lifecycle_img/overall_architecture.png)
Prerequisite  
- The subscription must opt in for this feature.
- EnablePendingDeletion=true tag configured on the VMSS.

## Overall Procedure
![Architecture Image](https://github.com/bedro96/terraform_vmss_ag/blob/master/vmss_lifecycle_img/procedure.png)

## Core components
**Web Service - healthprobe_flask**
![Architecture Image](https://github.com/bedro96/terraform_vmss_ag/blob/master/vmss_lifecycle_img/health_probe_handler.png )

**Delete VMSS Instance - delete_vmss_instance**
![Architecture Image](https://github.com/bedro96/terraform_vmss_ag/blob/master/vmss_lifecycle_img/delete_vmss_instance.png)

# Deployment
## Environment
Overall evnironment will be deployed from terraform with following characteristics.  
 - Availability Zone: not considered.
 - PublicLB: deployed with a NAT rule for ssh. 
 - MSI: Enabled and configured as contributor on resource group. 
 - Custom Extension: read bootstrap file.
 - VMSS scale-in policy: NewestVM, configured from the portal. 
 - Application Gateway: Backend pool and custom probe configured for this VMSS.
 - Applictions: Written in python, leverages Azure REST API and Azure SDK for python.
 - Managed Image: Managed Image, which has data disk will be referred.
 - VMID : Numeric id of VMSS instance is parsed from "name" of IMDS from each VMSS instance. 
 - Data Drive formatting : setup.sh has the code for fdisk and making an entry in /etc/fstab.
 - Managed Image : a managed image will be retrieved for provisioning of VMSS instance.
 - Versioning : This code supersedes https://github.com/bedro96/terraform_vmss_ag

## Terraform 
Clone this git and modify terraform.tfvars as required. Execute following commands to deploy the environment.

```bash
terraform init
terraform plan -out=vmss_ag.out
terraform apply vmss_ag.out
```
