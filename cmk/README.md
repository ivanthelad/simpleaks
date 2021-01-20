## Overview

These scripts deploys a CMK based AKS cluster with a CMK based ACR. The scripts by default use managed identity and enable AAD integration.

The reason behind two seperate script is to seperate resources that can be reused by multiple clusters. For example multiple clusters can reuse the key, disk encryption set, and ACR. There is no need to create all these again for additional clusters.

#### 1: Create a group in Azure AD and add your user account to it.

The steps how to do vary depending on whether you have access to Azure AD directly or your local identity management allows for synchronization of groups in your on-prem user directory to Azure AD. Regardless of how
this actually works, you will need a user group in which you are a member.

Once you know the name of the group you want to use, find its object ID by running

```
az ad group show -g <group-name> --query objectId -o tsv
```

#### 2: ./cmksetup:

This script creates the following.

-   Creates a Key Vault
-   Creates a default key in the Key Vault
-   Creates a managed identity for ACR and gives it wrap/unwrap/get rights against the Key Vault
-   Creates an Azure Container Registry and assigns the managed identity to use the default key that was just created in the Key Vault
-   Creates an DiskEncryptionSet resource. The DiskEncryptionSet gets an managed identity which is reterived and given wrap/unwrap/get against the keyvault.

The script outputs two variables that are intended to be used when creating CMK based cluster. You should add these to the `./env.sh` environment variable file. These variables can be resued across multiple cluster creations.

-   `ACR_REGISTRY_ID`: If found when executing `./simpleaks_cmk.sh` then this registry will be used for images by the cluster
-   `DISK_ENCRYPTION_SET_ID`: If found when executing `./simpleaks_cmk.sh` then this encycptionset will be used to encypte all the disks on a aks cluster. if not found the script will abort

Also, update `AAD_ADMIN_GROUP_ID`obtained from the first step.

#### 3: ./simpleaks_cmk.sh

##### Config setup

The script expects the following variables are set in a file called ./env.sh on relative path of `./simpleaks_cmk.sh.` Simply create this file or set the variables. The `env.sh` file is loaded as a source in `./simpleaks_cmk.sh.`

:warning: If any optional value is not provided then the script will create on for you

-   `SUBSCRIPTIONID`
-   `SP_ID`
-   `SP_PASS`
-   `DISK_ENCRYPTION_SET_ID`
-   `AAD_ADMIN_GROUP_ID`
-   `ACR_REGISTRY `(optional)
-   `WORKSPACE_ID `(optional)
-   `SUBNET_ID `(optional)
-   `AKS_IDENTITY_ID` (optional)

```
## Subscription where everything will be deployed
SUBSCRIPTIONID=""
## Service principal for AKS. known as APPID
## https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal#specify-a-service-principal-for-an-aks-cluster
SP_ID=""
## Service principal passwork
SP_PASS=""
## optional Azure Container Registry ID. If empty a new one will be created
ACR_REGISTRY=""
## Optional Azure log analytics Workspace ID. If empty a new one will be created
WORKSPACE_ID=""
## Optional Subnetid.AKS will be deployed into this subnet. If empty a new one will be created
SUBNET_ID=""
## Option. A user defined identity for the AKS Control plane. if not found one will be created.
AKS_IDENTITY_ID=""
## Required EncryptionSetid. if not found the the script will abort. required for aks to encrypt the hosts disks.
DISK_ENCRYPTION_SET_ID=""
## Required AAD Admin Group object id of Kubernetes admin group
AAD_ADMIN_GROUP_ID=""


```

### Preview Prerequisites

Please ensure the following previews are enabled.
<<<<<<< HEAD
** the script uses BYO managed identity preview. This means it precreates a user managed identity to be used on the managment plane. if you don't want this preview then you can simply comment out its usage in the script. [See line !](https://github.com/ivanthelad/simpleaks/blob/master/cmk/simpleaks_cmk.sh#L145) 
** https://docs.microsoft.com/en-us/azure/aks/enable-host-encryption
** https://docs.microsoft.com/en-us/azure/aks/use-managed-identity#bring-your-own-control-plane-mi-preview
 
#### Step for prereqs
* az extension add --name aks-preview
* az extension update --name aks-preview
* az feature register --name UserAssignedIdentityPreview --namespace Microsoft.ContainerService
* az feature register --name UserAssignedIdentityPreview --namespace Microsoft.ContainerService
* :warning: Ensure you reregister the container service after the preview is registered 
* az provider register --namespace Microsoft.ContainerService

### Deploying 
There are 2 scripts that setup the CMK with AKS environmnet. 
:warning: Before executing the script please ensure you are using the correct subscription. `az account set -s $subid`
1. Configure environment variables in ../env.sh
1. execute `./cmksetup.sh $UniqueParamNameForKeyvaultName` 
=======

-   https://docs.microsoft.com/en-us/azure/aks/enable-host-encryption
-   https://docs.microsoft.com/en-us/azure/aks/use-managed-identity#bring-your-own-control-plane-mi-preview

#### Step for prereqs

-   az extension add --name aks-preview
-   az extension update --name aks-preview
-   az feature register --name UserAssignedIdentityPreview --namespace Microsoft.ContainerService
-   :warning: Ensure you reregister the container service after the preview is registered
-   az provider register --namespace Microsoft.ContainerService

### Deploying

There are 2 scripts that setup the CMK with AKS environmnet.
:warning: Before executing the script please ensure you are using the correct subscription: `az account set -s $subid`

1. Configure environment variables in ../env.sh, including `AAD_ADMIN_GROUP_ID`
1. Execute `./cmksetup.sh $UniqueNameForKeyVault`
>>>>>>> e5a999102fb82d2081e038998ec82b3bd6fa24b5
1. Copy and paste the output variables from the `./cmksetup` into `../env.sh`
    1. DISK_ENCRYPTION_SET_ID
    1. AKS_IDENTITY_ID
1. Execute `./simple_cmk.sh $UniqueNameForAKS`
