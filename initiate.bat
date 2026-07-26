kubectl apply -f namespace.yaml

@REM tier 1

kubectl apply -f ./rdbms/postgresql-metadata.yaml -n rdbms
kubectl wait --for=condition=ready pod -l app=postgres-metadata -n rdbms --timeout=60s

kubectl apply -f ./minio/minio.yaml -n minio
kubectl wait --for=condition=ready pod -l app=minio -n minio --timeout=60s
kubectl apply -f ./minio/minio_initiate_task.yaml -n minio
@REM kubectl logs -n minio job/minio-bucket-init   

kubectl apply -f ./airflow/airflow_gitsync.yaml -n airflow
kubectl apply -f ./airflow/airflow_secret.yaml -n airflow
kubectl apply -f ./airflow/airflow_rbac.yaml -n airflow
kubectl apply -f ./airflow/airflow_configmap_common.yaml -n airflow
kubectl apply -f ./airflow/airflow_initiate_task.yaml -n airflow
kubectl wait --for=condition=ready pod -l app=airflow-init -n airflow --timeout=60s
@REM kubectl logs -n airflow job/airflow-init
kubectl apply -f ./airflow/airflow_worker.yaml -n airflow
kubectl apply -f ./airflow/airflow.yaml -n airflow