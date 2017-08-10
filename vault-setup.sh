#init CA
vault mount -path kubernetes pki
vault mount-tune -max-lease-ttl=87600h kubernetes

#generate root certificate
vault write kubernetes/root/generate/internal common_name=kubernetes ttl=87600h

#kubelet pki role
vault write kubernetes/roles/kubelet allowed_domains="kubelet" allow_bare_domains=true allow_subdomains=false max_ttl="720h"

#kube-proxy pki role
vault write kubernetes/roles/kube-proxy allowed_domains="kube-proxy" allow_bare_domains=true allow_subdomains=false max_ttl="720h"

#kube-scheduler pki role
vault write kubernetes/roles/kube-scheduler allowed_domains="kube-scheduler" allow_bare_domains=true allow_subdomains=false max_ttl="720h"

#service account secret key
KEY=$(openssl genrsa 4096) vault write secret/kubernetes/token key=$KEY

#kube-apiserver vault policy
cat <<EOT | vault policy-write kubernetes/policy/kube-apiserver -
path "kubernetes/issue/kube-apiserver" {
  policy = "write"
}
path "secret/kubernetes/token" {
  policy = "read"
}
EOT

#knode auth role
vault write auth/token/roles/knode period="720h" orphan=true allowed_policies="kubernetes/policy/kube-apiserver"

#knode issue cert
DATA=$(vault write --format=json kubernetes/issue/kubelet common_name=kubelet); echo $DATA|jq .data.certificate > knode-cert.pem; echo $DATA|jq .data.private_key > knode-key.pem; echo $DATA|jq .data.issuing_ca > knode-ca.pem

