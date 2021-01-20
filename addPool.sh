
echo "adding system pool "
az aks nodepool add -g $RESOURCE_GROUP --cluster-name $AKS_CLUSTER -n systemnodes --node-taints CriticalAddonsOnly=true:NoSchedule --mode system
echo "traefik ingress pool"
if  isempty "INGRESS_SUBNET_ID" "$INGRESS_SUBNET_ID"; then 
     echo -e "      \e[31mError\e[0m: no ingress subnet id found. will not create pool"
     errors=$((errors+1))
else 
      az aks nodepool add -g $RESOURCE_GROUP --cluster-name $AKS_CLUSTER -n ingress --vnet-subnet-id $INGRESS_SUBNET_ID --node-taints IngressOnly=true:NoSchedule --node-count=2 --node-count=2 --tags="Ingress=true"

fi