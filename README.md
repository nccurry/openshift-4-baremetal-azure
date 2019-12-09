# OpenShift 3.11 Azure

## Deploy prerequisites

These playbooks assume the following have already been created in an Azure environment. 

Information about deploying OpenShift 3.11 into Azure can be found [here](https://docs.openshift.com/container-platform/3.11/install_config/configuring_azure.html)

More information about deploying OpenShift 3.11 in general can be found [here](https://docs.openshift.com/container-platform/3.11/install/index.html)

- Service principal for terraform with appropriate permissions to deploy cluster resources
- Service principal for OpenShift with appropriate permissions to provision storage
- Resource Group to deploy objects into
- Virtual Network / Subnetwork
- DNS Zone

## Set environment variables

```shell script
# Temporarily ignore shell history when command has leading space 
HISTCONTROL=ignorespace

# Store azure terraform provider variables
# We don't want these accidentally laying around since they are sensitive
# These get picked up automatically by the terraform azure provider
 ARM_CLIENT_ID=<service principal id>
 ARM_SUBSCRIPTION_ID=<subscription id>
 ARM_TENANT_ID=<tenant id>
 ARM_CLIENT_SECRET=<service principal secret>
```

## Deploy terraform templates

```shell script
terraform init
terraform apply -var-file="environment.tfvars"
```

## Miscellaneous

```shell script
# List all azure regions
az account list-locations -o table

# List resource group with name 'groupname'
az group list --query '[?name == `groupname`]'



```