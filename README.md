# OpenShift 4.x Custom UPI Azure

Terraform plans to deploy a custom UPI OpenShift cluster on Azure before the official functionality is released.

## Deploy prerequisites

These playbooks assume the following have already been created in an Azure environment. 
- Service principal for terraform with appropriate permissions to deploy cluster resources
- Service principal for OpenShift with appropriate permissions to provision storage
- Resource Group to deploy objects into
- Virtual Network / Subnetwork
- DNS Zone

And the following are met by the host
- openshift-install binary on PATH
- terraform binary on PATH

### Create service principal for terraform

```shell script
resourceGroupName='resourcegroup'
servicePrincipalName='ocp4-terraform'
resourceGroupId=$(az group list --query "[?name == '${resourceGroupName}'] | [0].id" -o tsv)

# Create service principal - Role list here: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
servicePrincipal=$(az ad sp create-for-rbac --name ${servicePrincipalName} --scope ${resourceGroupId} --role 'Contributor')
servicePrincipalId=$(echo ${servicePrincipal} | jq -r .appId)
servicePrincipalPassword=$(echo ${servicePrincipal} | jq -r .password)
```

## Set environment variables 

An example of the parameters required can be found at [vars/example.yml](vars/example.yml)

```shell script
cp vars/example.yml vars/<environment>.yml
```

## Run ansible playbooks

```shell script
# Generate ignition files
 ./playbooks/ocp.yml -v -e '@vars/<environment>.yml' -t openshift_azure_storage_ignition
# Delete ignition files
 ./playbooks/ocp.yml -v -e '@vars/<environment>.yml' -t openshift_azure_storage_ignition -e teardown=true

# Deploy RHCOS image
 ./playbooks/ocp.yml -v -e '@vars/<environment>.yml' -t az_ocp_rhcos_image
# Delete RHCOS image
 ./playbooks/ocp.yml -v -e '@vars/<environment>.yml' -t az_ocp_rhcos_image -e teardown=true

# Deploy OpenShift
 ./playbooks/ocp.yml -v -e '@vars/<environment>.yml' -t az_ocp_infra
# Delete OpenShift 
 ./playbooks/ocp.yml -v -e '@vars/<environment>.yml' -t az_ocp_infra -e teardown
```

## Miscellaneous

```shell script
# Log in as service principal 
servicePrincipalId=''
servicePrincipalSecret=''
tenant=''
az login --service-principal -u ${servicePrincipalId} -p ${servicePrincipalSecret} --tenant ${tenantId}

# List all azure regions
az account list-locations -o table

# List resource group with name 'groupname'
resourceGroupName='resourcegroup'
az group list --query "[?name == '${resourceGroupName}'] | [0]"

# List all azure roles
az role definition list -o table

# List service principal information
servicePrincipalName='ocp4-terraform'
az ad sp list --query "[?appDisplayName=='${servicePrincipalName}'] | [0]"

# Delete service principal 
servicePrincipalId=$(az ad sp list --query "[?appDisplayName=='${servicePrincipalName}'] | [0].appId" -o tsv)
az ad sp delete --id ${servicePrincipalId}
```