{
  "tenantId": "xxxxx",
  "subscriptionId": "xxxx",
  "resourceGroup": "aksonazure",
  "useManagedIdentityExtension": true
}

kubectl create secret generic azure-config-file --from-file=azure.json -n externaldns


{
  "tenantId": "xxxxx",
  "subscriptionId": "xxxxx",
  "resourceGroup": "MyDnsResourceGroup",
  "useManagedIdentityExtension": true
}