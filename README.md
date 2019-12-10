# OpenShift 4.x Custom UPI Azure

Terraform plans to deploy a custom UPI OpenShift cluster on Azure before the official functionality is released.

## Deploy prerequisites

These playbooks assume the following have already been created in an Azure environment. 
- Service principal for terraform with appropriate permissions to deploy cluster resources
- Service principal for OpenShift with appropriate permissions to provision storage
- Resource Group to deploy objects into
- Virtual Network / Subnetwork
- DNS Zone

### Create service principal for terraform

```shell script
# Get resource group id
resourceGroupId=$(az group list --query '[?name == `mygroup`] | [0].id')



# Create service principal
az ad sp create-for-rbac --name {appId} --password "{strong password}" --scopes ${resourceGroupId}
```

## Set environment variables

```shell script
# Temporarily ignore shell history when command has leading space 
HISTCONTROL=ignorespace

# Store azure terraform provider variables
# We don't want these accidentally laying around since they are sensitive
# These get picked up automatically by the terraform azure provider
 ARM_CLIENT_SECRET=<service principal secret>
```

## Run ansible playbooks

```shell script
# Generate ignition files
 ./playbooks/ocp.yml -v -e '@vars/<environment>.yml' -t ocp_ignition

# Deploy OpenShift terraform template
 ./playbooks/ocp.yml -v -e '@vars/<environment>.yml' -t az_ocp_infra
```

## Miscellaneous

```shell script
# List all azure regions
az account list-locations -o table

# List resource group with name 'groupname'
az group list --query '[?name == `groupname`] | [0]'

# List all azure roles
az role definition list -o table
```