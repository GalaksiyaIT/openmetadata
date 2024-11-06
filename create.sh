for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet

containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml  
service containerd restart
service kubelet restart

IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "kubeadm init --pod-network-cidr=192.168.0.0/16 --control-plane-endpoint=$IP_ADDRESS"

sed -i '/swap/ s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a

kubeadm init --pod-network-cidr=192.168.0.0/16 --control-plane-endpoint=$IP_ADDRESS

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/custom-resources.yaml -O
kubectl create -f custom-resources.yaml

kubectl taint nodes openmetadata node-role.kubernetes.io/control-plane:NoSchedule-

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

mkdir /mnt/
mkdir /mnt/vol0 /mnt/vol1 /mnt/vol2 /mnt/vol3
chmod -R 777 /mnt/vol0 /mnt/vol1 /mnt/vol2 /mnt/vol3

current_hostname=$(hostname)
sed -i "s/openmetadata/$current_hostname/g" ./pv.yaml
sed -i "s/127.0.0.1/$IP_ADDRESS/g" ./ingress-nginx/custom-values.yaml