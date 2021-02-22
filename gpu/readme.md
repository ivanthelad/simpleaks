az aks nodepool add --name gpus --cluster-name gpubits-7fdff --resource-group gpubits-7fdff --node-vm-size Standard_NC6 --node-count 1 --aks-custom-headers UseGPUDedicatedVHD=true



az aks nodepool add --name gpus3 --cluster-name gpubits-7fdff --resource-group gpubits-7fdff --node-vm-size Standard_NC6  --aks-custom-headers UseGPUDedicatedVHD=true --node-taints GPUOnly=true:NoSchedule --node-count=1  --tags="GPU=true"    --max-count=2  --min-count=0


az aks nodepool add --name gpus5 --enable-cluster-autoscaler  --cluster-name gpubits-7fdff --resource-group gpubits-7fdff --node-vm-size Standard_NC6  --aks-custom-headers UseGPUDedicatedVHD=true --node-taints GPUOnly=true:NoSchedule   --tags="GPU=true"  --max-count=2  --min-count=0  --node-count=0

az aks nodepool add --name gpus --cluster-name gpubits-7fdff --resource-group gpubits-7fdff --node-vm-size Standard_NC6 --node-count 1 --aks-custom-headers UseGPUDedicatedVHD=true --node-taints GPUOnly=true:NoSchedule --node-count=1  --tags="GPU=true"  

## example pod 

''
apiVersion: v1
kind: Pod
metadata:
  name: with-node-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: "agentpool"
            operator: In
            values:
            - "gpus5"
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: "agentpool"
            operator: In
            values:
            - "gpus5"
  containers:
  - name: with-node-affinity
    image: k8s.gcr.io/pause:2.0
  tolerations:
  - key: "GPUOnly"
    value: "true"
    operator: "Equal"
    ''