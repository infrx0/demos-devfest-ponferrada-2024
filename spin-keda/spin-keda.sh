#PREREQUISITOS
sudo apt update -y; apt-get upgrade -y;
sudo apt install apt-transport-https ca-certificates curl software-properties-common golang-go -y
sudo snap install kubectl --classic
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce -y
sudo usermod -aG docker ${USER}

#INICIALIZACIÓN K3D
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

k3d cluster create wasm-cluster-scale \
  --image ghcr.io/spinkube/containerd-shim-spin/k3d:v0.15.1 \
  -p "8081:80@loadbalancer" \
  --agents 2

#INSTALACIÓN K3D
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.3

#INSTALACIÓN SPINKUBE
kubectl apply -f https://github.com/spinkube/spin-operator/releases/download/v0.3.0/spin-operator.runtime-class.yaml
kubectl apply -f https://github.com/spinkube/spin-operator/releases/download/v0.3.0/spin-operator.crds.yaml
helm install spin-operator \
  --namespace spin-operator \
  --create-namespace \
  --version 0.3.0 \
  --wait \
  oci://ghcr.io/spinkube/charts/spin-operator
kubectl apply -f https://github.com/spinkube/spin-operator/releases/download/v0.3.0/spin-operator.shim-executor.yaml

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: keda-spinapp
            port:
              number: 80
EOF

INSTALACIÓN HERRAMIENTA BENCHMARKING
go install github.com/nakabonne/ali@latest
export PATH=$PATH:$HOME/go/bin
source ~/.bashrc
ali --duration=5m --rate=500 http://localhost:8081

INSTALACIÓN KUBE-OPS VIEW
git clone https://codeberg.org/hjacobs/kube-ops-view.git
cd kube-ops-view/deploy
kubectl apply -k deploy

INSTALACIÓN KEDA
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda --namespace keda --create-namespace
kubectl apply -f https://raw.githubusercontent.com/spinkube/spin-operator/main/config/samples/keda-app.yaml
kubectl apply -f https://raw.githubusercontent.com/spinkube/spin-operator/main/config/samples/keda-scaledobject.yaml
