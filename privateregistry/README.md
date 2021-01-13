helm install csi-secrets-store-provider-azure/csi-secrets-store-provider-azure --generate-name --dry-run  |grep image: 
          image: quay.io/k8scsi/csi-node-driver-registrar:v1.2.0
          image: "us.gcr.io/k8s-artifacts-prod/csi-secrets-store/driver:v0.0.12"
          image: quay.io/k8scsi/livenessprobe:v2.0.0
          image: "mcr.microsoft.com/k8s/csi/secrets-store/provider-azure:0.0.7"
## helm install csi-secrets-store-provider-azure/csi-secrets-store-provider-azure --generate-name --dry-run
## 1 echo           image: quay.io/k8scsi/csi-node-driver-registrar:v1.2.0| awk -F":" ' { print substr($1,1,11) }'
###  echo quay.io/k8scsi/csi-node-driver-registrar:v1.2.0 | awk -F'/' '{print $2}' 
## gives a list of images that need to be made avaiable to the end 

docker pull   quay.io/k8scsi/csi-node-driver-registrar:v1.2.0
docker pull  us.gcr.io/k8s-artifacts-prod/csi-secrets-store/driver:v0.0.12 
docker pull quay.io/k8scsi/livenessprobe:v2.0.0

docker tag   quay.io/k8scsi/csi-node-driver-registrar:v1.2.0 aksonazure.azurecr.io/k8scsi/csi-node-driver-registrar:v1.2.0
 docker tag  us.gcr.io/k8s-artifacts-prod/csi-secrets-store/driver:v0.0.12 aksonazure.azurecr.io/k8s-artifacts-prod/csi-secrets-store/driver:v0.0.12
docker tag quay.io/k8scsi/livenessprobe:v2.0.0  aksonazure.azurecr.io/k8scsi/livenessprobe:v2.0.0

docker push  aksonazure.azurecr.io/k8scsi/csi-node-driver-registrar:v1.2.0
docker push  aksonazure.azurecr.io/k8s-artifacts-prod/csi-secrets-store/driver:v0.0.12
docker push  aksonazure.azurecr.io/k8scsi/livenessprobe:v2.0.0