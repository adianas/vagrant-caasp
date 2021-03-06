#!/bin/bash
echo "Installing Kubernetes Dashboard..."
#helm install stable/kubernetes-dashboard --namespace kube-system --name kubernetes-dashboard --set service.type=NodePort
# dashboard chart and dashboard not ready for 1.16.2
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended.yaml
kubectl patch svc kubernetes-dashboard --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]' -n kubernetes-dashboard

cat >/tmp/dashboard-admin.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
EOF

kubectl apply -f /tmp/dashboard-admin.yaml

cat >/tmp/admin-user-crb.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: admin-user
    namespace: kube-system
EOF

kubectl apply -f /tmp/admin-user-crb.yaml

rm -f /tmp/dashboard-admin.yaml /tmp/admin-user-crb.yaml 2>/dev/null

#helm status kubernetes-dashboard

####export NODE_PORT=$(kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services kubernetes-dashboard -n kube-system)
####export NODE_IP=$(kubectl get nodes -o jsonpath="{.items[0].status.addresses[0].address}" -n kube-system)
####

#ST=$(kubectl -n kubernetes-dashboard get serviceaccounts kubernetes-dashboard -o jsonpath="{.secrets[0].name}")
#SECRET=$(kubectl -n kubernetes-dashboard get secret ${ST} -o jsonpath="{.data.token}"|base64 -d)
ST=$(kubectl -n kube-system get serviceaccounts admin-user -o jsonpath="{.secrets[0].name}")
SECRET=$(kubectl -n kube-system get secret ${ST} -o jsonpath="{.data.token}"|base64 -d)
export NODE_PORT=$(kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services kubernetes-dashboard -n kubernetes-dashboard)
export NODE_IP=$(kubectl get nodes -o jsonpath="{.items[0].status.addresses[0].address}" -n kubernetes-dashboard)

echo "    token: $SECRET" >> ~/.kube/config
echo "Access your dashboard at: https://$NODE_IP:$NODE_PORT/"
echo "Your login token is: ${SECRET}"
echo "Or use ~/.kube/config to authenticate with kubeconfig"

