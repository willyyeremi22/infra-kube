@REM kubectl apply -f namespace.yaml

@REM @REM tier 1

@REM kubectl apply -f ./rdbms/postgresql-metadata.yaml -n rdbms
@REM kubectl wait --for=condition=ready pod -l app=postgres-metadata -n rdbms --timeout=60s

@REM kubectl apply -f ./minio/minio.yaml -n minio
@REM kubectl wait --for=condition=ready pod -l app=minio -n minio --timeout=60s
@REM kubectl apply -f ./minio/minio_initiate_task.yaml -n minio
@REM @REM kubectl logs -n minio job/minio-bucket-init   

kubectl delete -f ./airflow/airflow_gitsync.yaml -n airflow
kubectl delete -f ./airflow/airflow_secret.yaml -n airflow
kubectl delete -f ./airflow/airflow_rbac.yaml -n airflow
kubectl delete -f ./airflow/airflow_configmap_common.yaml -n airflow
kubectl delete -f ./airflow/airflow_initiate_task.yaml -n airflow
@REM kubectl wait --for=condition=ready pod -l app=airflow-init -n airflow --timeout=60s
@REM kubectl logs -n airflow job/airflow-init
kubectl delete -f ./airflow/airflow_worker.yaml -n airflow
kubectl delete -f ./airflow/airflow.yaml -n airflow