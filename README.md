

## Tanka
Installs kube-prometheus stack (not grafana) and kube-thanos. Includes minio bucket that must be installed outside tanka

prometheus + thanos sidecar
thanos store
thanos querier
minio bucket


Use node
### Steps
Update "apiServer" in environments/test/spec.json to point to the local k8s cluster
jb install
tk export environments/test export  --format "{{.kind}}-{{.metadata.name}}-{{.metadata.namespace}}"
Create bucket: kubectl --context=[YOURCONTEXT] apply -f bucket/ 
Create everything: kubectl --context=[YOURCONTEXT] apply -f export/
Use this to enter to thanos querier and see metrics: kubectl port-forward --namespace=monitoring service/thanos-query 9090  --context [YOURCONTEXT]

