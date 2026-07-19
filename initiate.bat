kubectl apply -f namespace.yaml

@REM tier 1

kubectl apply -f ./rdbms/postgresql-metadata.yaml -n rdbms
kubectl wait --for=condition=ready pod -l app=postgres-metadata -n rdbms --timeout=60s

kubectl apply -f ./opensearch/opensearch_secret.yaml -n opensearch
kubectl apply -f ./opensearch/opensearch_configmap_common.yaml -n opensearch
kubectl apply -f ./opensearch/opensearch.yaml -n opensearch
kubectl wait --for=condition=ready pod -l app=opensearch-cluster-manager -n opensearch --timeout=60s
kubectl apply -f ./opensearch/opensearch_initiate_task.yaml -n opensearch
@REM kubectl logs -n opensearch job.batch/opensearch-init

kubectl apply -f ./openldap/openldap.yaml -n openldap
timeout /T 60 /nobreak

kubectl apply -f ./ranger/ranger_admin.yaml -n ranger
kubectl wait --for=condition=ready pod -l app=ranger-admin -n ranger --timeout=60s
timeout /T 60 /nobreak
kubectl apply -f ./ranger/ranger_usersync.yaml -n ranger