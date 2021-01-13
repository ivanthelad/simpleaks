 helm upgrade --install loki loki/loki-stack  --set grafana.enabled=true,prometheus.enabled=true,prometheus.alertmanager.persistentVolume.enabled=false,prometheus.server.persistentVolume.enabled=false,loki.persistence.enabled=true,loki.persistence.storageClassName=standard,loki.persistence.size=5Gi

 ### Get pwd 

    
 

kubectl get secret --namespace monitoring  loki-grafana -o jsonpath="{​​​​​​​​.data.admin-password}​​​​​​​​" | base64 --decode ; echo





