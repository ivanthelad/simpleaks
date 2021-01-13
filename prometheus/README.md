## install promethues 
See documentation 
 * https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack

### Commands
``` 
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

Install 
```
kubectl create namespace prom
helm install prom prometheus-community/kube-prometheus-stack -n prom --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
```
### Get pwd grafana 
kubectl get secret --namespace prom prom2-grafana -o jsonpath="{​​​​​​​​.data.admin-password}​​​​​​​​" | base64 --decode ; echo

kubectl get secret -n prom prom2-grafana -o jsonpath="{.data.admin-password}" |base64 --decode; echo 

### Access to console 
 kubectl port-forward   $podid -n prom  3001:3000



## IOPS ISSUE 
https://github.com/jnoller/kubernaughty
https://github.com/Azure/AKS/issues/1373
https://github.com/jnoller/kubernaughty/issues/46





 ### test with vm 
 https://docs.microsoft.com/en-us/azure/aks/cluster-configuration#use-ephemeral-os-on-existing-clusters-preview
 Standard_DS3_v2 vms size and ephermal disks 


### Golden Signals 

https://sysdig.com/blog/golden-signals-kubernetes/