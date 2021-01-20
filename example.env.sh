## Subscription where everything will be deployed
SUBSCRIPTIONID=""
## Service principal for AKS. known as APPID
## https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal#specify-a-service-principal-for-an-aks-cluster
SP_ID=""
## Service principal passwork
SP_PASS="t"
## optional Azure Container Registry ID. If empty a new one will be created
#ACR_REGISTRY=""
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
VM_SIZE=Standard_D2s_v3
MIN_NODE_COUNT=3
MAX_NODE_COUNT=4
KUBE_VERSION=1.17.9
LOCATION=westeurope

## kubenet or azure
NETWORK_PLUGIN="kubenet"
