kubectl create namespace openmetadata

kubectl apply -f storage-class.yaml
kubectl patch storageclass local-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl apply -f pv.yaml

kubectl create secret generic postgres-secrets --from-literal=openmetadata-postgres-password=n6NsLT5gduAU3P8aYV42KE -n openmetadata
kubectl create secret generic airflow-secrets --from-literal=openmetadata-airflow-password=b4Wv2K659XLymdxgJjVrqw -n openmetadata
kubectl create secret generic airflow-postgres-secrets --from-literal=airflow-postgres-password=GJ9XkVeYWDzQmxvCcjRadA -n openmetadata
 
helm upgrade --install openmetadata-dependencies deps -n openmetadata -f deps/ci/custom_values.yaml

helm upgrade --install openmetadata openmetadata -n openmetadata --create-namespace -f openmetadata/ci/custom_values.yaml

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/custom-resources.yaml -O
kubectl create -f custom-resources.yaml