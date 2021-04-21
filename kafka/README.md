sed -i 's/namespace: .*/namespace: kafka/' install/cluster-operator/*RoleBinding*.yaml
install/cluster-operator/060-Deployment-strimzi-cluster-operator.yaml


https://strimzi.io/docs/operators/latest/full/deploying.html#deploying-cluster-operator-to-watch-whole-cluster-str


helm repo add strimzi https://strimzi.io/charts/
helm install strimzi/strimzi-kafka-operator
kubectl apply -f examples/kafka/kafka-persistent.yaml
kubectl apply -f kafka-topic.yaml



kubectl apply -f examples/mirror-maker/kafka-mirror-maker.yaml
https://strimzi.io/blog/2020/06/09/mirror-maker-2-eventhub/



producer 
kubectl -n kafka run kafka-producer -ti --image=strimzi/kafka:0.20.1-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh --broker-list my-cluster-kafka-bootstrap:9092 --topic testeh



kafka-console-consumer.sh --bootstrap-server kubeevenhub2.servicebus.windows.net:9093 --topic my-cluster.testeh --consumer.config kafka-eventhub.properties
strimzi/kafka:0.20.1-kafka-2.5.0

 1823  bin/kafka-console-consumer.sh --bootstrap-server <eventhubs-namespace>.servicebus.windows.net:9093 --topic my-cluster.testeh --consumer.config kafka_eventhub.properties
 1824  bin/kafka-console-consumer.sh --bootstrap-server <eventhubs-namespace>.servicebus.windows.net:9093 --topic my-cluster.testeh --consumer.config kafka-eventhub.properties

## demo content 
 {"Title": "WO-0123-458","DeliveryTo": "Plant München","Position": [1,2,3,4,5,], "PartID": ["P-098-767", "P-098-768", "P-098-769", "P-098-766", "P-098-765"], Amount: [31,32,39,31,20]}