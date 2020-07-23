#!/bin/bash
## neable app insights https://github.com/microsoft/Application-Insights-K8s-Codeless-Attach
source ./env.sh 
uuid=$(openssl rand -hex 32 | tr -dc 'a-zA-Z0-9' | fold -w 5  | head -n 1)
clusternameparam=$1
function  isempty ()
{
   paramname="$1"
   paramvalue="$2"

      if test -z "$paramvalue" 
      then
            echo -e "   \e[31mError\e[0m:$paramname is EMPTY, Please paas a parameter for the $paramname"
          return 0 
     else
           echo  -e "   \e[32m OK\e[0m   :$paramname=$paramvalue is set"
      fi
      return 1

}
function  sanitycheck ()
{

      errors=0;
      if  isempty "clusternameparam" "$clusternameparam"; then 
            echo -e "      \e[31mError\e[0m: No param passed to script. A cluster name is required to be passed to script"
            errors=$((errors+1))
      fi
      if  isempty "SP_ID" "$SP_ID"; then 
            errors=$((errors+1))
      fi
      if  isempty "SP_PASS" "$SP_PASS"; then 
            errors=$((errors+1))
      fi
      if  isempty "SUBSCRIPTIONID" "$SUBSCRIPTIONID"; then 
            errors=$((errors+1))
      fi  
      if  isempty "WORKSPACE_ID" "$WORKSPACE_ID"; then 
            echo -e "      \e[33mWarn\e[0m: WORKSPACE_ID not set. A new log analytics workspace will be created and used"
      fi  
      if  isempty "ACR_REGISTRY" "$ACR_REGISTRY"; then 
             echo -e "     \e[33mWarn\e[0m: ACR_REGISTRY not set. A new Azure Container Registry  will be created and used"
      fi  
      if  isempty "SUBNET_ID" "$SUBNET_ID"; then 
            echo -e "      \e[33mWarn\e[0m: SUBNET_ID not set. A new Azure Container Registry  will be created and used"
      fi
      if [ $errors -gt 0 ]; then
          echo -e "   \e[31mEncountered $errors in parameters. Please fix before continuing. exiting \e[0m "
          exit 1;
      fi 
}
sanitycheck
 

aksname="$clusternameparam-$uuid"
registryname="${clusternameparam}${uuid}reg"
gw_name="${aksname}-gw"
echo "Creating cluster with name $aksname "

RESOURCE_GROUP=$aksname
AKS_CLUSTER=$aksname

VM_SIZE=Standard_D2s_v3
MIN_NODE_COUNT=3
MAX_NODE_COUNT=4
KUBE_VERSION=1.17.7
LOCATION=westeurope
network_prefix='10.3.0.0/16'
network_aks_subnet='10.3.0.0/22'

network_aks_system='10.3.4.0/24'
## GW subnet
gw_network_prefix='10.19.0.0/16'
gw_network_subnet='10.19.0.0/22'



LB_IDLE_TIMEOUT=10
OS_DISK_SIZE=50
## Some basic tags 
tags=`echo Environment=dev Project=minipoc Department=engineering`
pool_tags=`echo Environment=dev Project=minipoc Department=engineering`

## az acr show --name aksonazure      --resource-group aksonazure      --query "id" --output tsv

#Create a RG
az group create --name  $RESOURCE_GROUP -l $LOCATION  --subscription $SUBSCRIPTIONID --tags $tags
if test -z "$ACR_REGISTRY" 
then
      echo "ACR_REGISTRY is empty, Gona create a Registry  in RG $RESOURCE_GROUP "
      az acr create -n  $registryname -g $RESOURCE_GROUP -l $LOCATION  --sku standard
      ACR_REGISTRY="$(az acr show -n  $registryname -g $RESOURCE_GROUP --query id  -o tsv --subscription $SUBSCRIPTIONID)"
      echo "created log analytics workspace with id $ACR_REGISTRY" 
else
      echo "\ACR_REGISTRY is is NOT empty. using $ACR_REGISTRY "
fi

if test -z "$WORKSPACE_ID" 
then
      echo "WORKSPACE_ID is empty, Gona create a Log analytics workspace in RG $RESOURCE_GROUP "
      az monitor log-analytics workspace create --workspace-name $aksname-logs -g $RESOURCE_GROUP -l $LOCATION --subscription $SUBSCRIPTIONID --tags $tags
      WORKSPACE_ID="$(az monitor log-analytics workspace show --workspace-name $aksname-logs -g $RESOURCE_GROUP --query id  -o tsv --subscription $SUBSCRIPTIONID)"
      echo "created log analytics workspace with id $WORKSPACE_ID" 
else
      echo "\Workspace_id is is NOT empty. using $WORKSPACE_ID "
fi
#Create a VNET
if test -z "$SUBNET_ID" 
then
      echo "SUBNET_ID is empty, Gona create a custom vnet in RG $RESOURCE_GROUP "
      az network vnet create -g $RESOURCE_GROUP -n $aksname --address-prefix $network_prefix  --tags $tags --subnet-name aks --subnet-prefix $network_aks_subnet -l $LOCATION  --subscription $SUBSCRIPTIONID
      SUBNET_ID="$(az network vnet subnet list --resource-group $RESOURCE_GROUP --vnet-name $aksname --query [].id --output tsv  --subscription $SUBSCRIPTIONID   | grep aks)"
    
    
else
      echo "\SUBNET_ID is is NOT empty. using $SUBNET_ID "
fi
#az network vnet create -g $RESOURCE_GROUP -n $aksname --address-prefix $network_prefix  --tags $tags --subnet-name aks --subnet-prefix $network_aks_subnet -l $LOCATION  --subscription $SUBSCRIPTIONID

#Create a AKS subnet. not needed. created above. 
echo "Creating public ip for AppGW"
az network public-ip create -n $gw_name-PublicIp -g $RESOURCE_GROUP --allocation-method Static --sku Standard
echo "Creating AppGW vnet"
az network vnet create -n  $gw_name-vnet -g  $RESOURCE_GROUP --address-prefix $gw_network_prefix --subnet-name gwsubnet --subnet-prefix $gw_network_subnet 
echo "Creating AppGW instance"
az network application-gateway create -n $gw_name -l $LOCATION -g $RESOURCE_GROUP --sku Standard_v2 --public-ip-address $gw_name-PublicIp --vnet-name $gw_name-vnet --subnet gwsubnet

#List Subnet belonging to VNET
echo $SUBNET_ID

## need to figure out RG and vnet name to peer. need to do this in the event someone supplies an subnet
##
AKS_VNET_RG=$(echo $SUBNET_ID|cut -d'/' -f 5) 
AKS_VNET=$(echo $SUBNET_ID| cut -d'/' -f 9)
## now i got the vnet id for the aks cluster and appgw vnet
aksVnetId=$(az network vnet show -n $AKS_VNET -g $AKS_VNET_RG -o tsv --query "id")
appGWVnetId=$(az network vnet show -n $gw_name-vnet -g $RESOURCE_GROUP -o tsv --query "id")

## perform the two way peering 
echo "Creating peering from AppGW vnet to AKS Vnet "
az network vnet peering create -n AppGWtoAKSVnetPeering -g $RESOURCE_GROUP --vnet-name $gw_name-vnet --remote-vnet $aksVnetId --allow-vnet-access
echo "Creating Peering from AKS vnet  to AppGW vnet "
az network vnet peering create -n AKStoAppGWVnetPeering -g $AKS_VNET_RG --vnet-name $AKS_VNET --remote-vnet $appGWVnetId --allow-vnet-access

## Creating keyVault
echo "Creating AKS Keyvault"
az keyvault create --name "${aksname}-kv" --resource-group $RESOURCE_GROUP --location $LOCATION

echo "Creating AKS Cluster "

#Create AKS Cluster with Service Principle
az aks create \
 --service-principal $SP_ID \
 --client-secret $SP_PASS \
 --resource-group $RESOURCE_GROUP \
 --network-plugin "kubenet" \
 --node-count $MIN_NODE_COUNT \
 --node-vm-size=$VM_SIZE \
 --kubernetes-version=$KUBE_VERSION \
 --name $AKS_CLUSTER \
 --docker-bridge-address "19.5.0.1/16" \
 --dns-service-ip "10.19.0.10" \
 --service-cidr "10.19.0.0/16" \
 --location $LOCATION \
 --enable-addons monitoring \
 --vm-set-type "VirtualMachineScaleSets"   \
 --tags $tags \
 --nodepool-name="basepool" \
 --vnet-subnet-id $SUBNET_ID \
 --enable-cluster-autoscaler \
 --min-count $MIN_NODE_COUNT \
 --max-count $MAX_NODE_COUNT \
 --subscription $SUBSCRIPTIONID \
 --workspace-resource-id $WORKSPACE_ID \
 --nodepool-tags $pool_tags \
 --nodepool-labels $pool_tags \
 --generate-ssh-keys \
 --zones 3 
##  --enable-aad \
## --aad-admin-group-object-ids "f7976ea3-24ae-40a2-b546-00c369910444" \
 

### ADDing appGW 
appgwId=$(az network application-gateway show -n $gw_name -g $RESOURCE_GROUP -o tsv --query "id") 
echo "App Gatewayid $appgwId, enabling addon" 
az aks enable-addons -n $AKS_CLUSTER -g $RESOURCE_GROUP -a ingress-appgw --appgw-id $appgwId
echo "successfully added addon for app gw "

echo "Adding system pool  "
az aks nodepool add -g $RESOURCE_GROUP --cluster-name $AKS_CLUSTER -n systemnodes --node-taints CriticalAddonsOnly=true:NoSchedule --mode system
# security policy 

### https://azure.github.io/application-gateway-kubernetes-ingress/annotations/#list-of-supported-annotations

# --enable-pod-security-policy  \

az aks get-credentials -n $AKS_CLUSTER -g $RESOURCE_GROUP

exit 0;
##https://strimzi.io/docs/latest/full.html#deploying-cluster-operator-helm-chart-str
kubectl  create namespace kafka
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
## see https://strimzi.io/docs/operators/master/using.html#deploying-cluster-operator-helm-chart-str
helm repo add strimzi https://strimzi.io/charts/

helm install strimy strimzi/strimzi-kafka-operator    -n kafka --set watchAnyNamespace=true
kubectl create clusterrolebinding strimzi-cluster-operator-namespaced --clusterrole=strimzi-cluster-operator-namespaced --serviceaccount kafka:strimzi-cluster-operator
kubectl create clusterrolebinding strimzi-cluster-operator-entity-operator-delegation --clusterrole=strimzi-entity-operator --serviceaccount kafka:strimzi-cluster-operator
kubectl create clusterrolebinding strimzi-cluster-operator-topic-operator-delegation --clusterrole=strimzi-topic-operator --serviceaccount kafka:strimzi-cluster-operator
kubectl set env deployment strimzi-cluster-operator STRIMZI_NAMESPACE="*" 
kafkaversion="0.18.0"
kubectl apply -f https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/$kafkaversion/examples/kafka/kafka-persistent.yaml
