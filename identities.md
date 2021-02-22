Below is a summary of Identities that are created in AKS. These identities are the main identities that will be created for each cluster.  The only one that would need to be know before hand, for networking, would be the control plane identity.  The  others from my opinion can be created on the fly with each cluster. There is an entire break down of the identities here  


Control Plane identity 
https://docs.microsoft.com/en-us/azure/aks/use-managed-identity#summary-of-managed-identities
When you create a cluster with the flag --managed-identity. Azure will create a system managed identity in the background.  You can find this identity by executing the following query 
az aks show -g myResourceGroup -n myManagedCluster --query "identity"
 
This identity is used for managing kubernetes network. Creating loadbalancers, Ips and attaching to network
This is a system managed identity  Is current a GA feature 
 
By default this is a system managed identity it means you do not know the identity until the cluster is created. This introduces issues as this identity will be required to attach to you  Networks and will not have the roles to do so. It is also problematic for automation(how can a person roles if the persons doesn't exist).
https://github.com/Azure/AKS/issues/1591
https://github.com/Azure/AKS/issues/1622
 
It is recommend  to use a user assigned identity for the control plane. This would enable you to define which roles  the identity requires. This feature is GA 
https://docs.microsoft.com/en-us/azure/aks/use-managed-identity#bring-your-own-control-plane-mi
 

$clustername-AgentPool
This identity is used to authenticate against and ACR registry.  When you use -Attach-ACR this identity will be give ACRPull role against your predefined ACR registry 
 
$OMS-agent 
This identity is responsible for sending metrics to Log analytics 


Note: 
old clusters can be upgraded to use managed identities https://docs.microsoft.com/en-us/azure/aks/use-managed-identity#update-an-aks-cluster-to-managed-identities-preview