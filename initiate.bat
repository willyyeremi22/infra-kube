docker build -f dockerfile.airflow_fab_s3 -t apache/airflow:3.2.2-python3.14-fab-s3 .
docker build -f dockerfile.airflow_fab -t apache/airflow:3.2.2-python3.14-fab .
docker build -f dockerfile.ranger_admin -t apache/ranger-custom-admin:2.8.0 . 2>&1 | Tee-Object -FilePath build.log
docker build -f dockerfile.ranger_usersync -t apache/ranger-custom-usersync:2.8.0 .

kubectl apply -f namespace.yaml

@REM tier 1

kubectl apply -f ./rdbms/postgresql-metadata.yaml -n rdbms
kubectl apply -f ./rdbms/postgresql-ops.yaml -n rdbms
kubectl wait --for=condition=ready pod -l app=postgres -n rdbms --timeout=60s

kubectl apply -f minio.yaml -n minio
kubectl wait --for=condition=ready pod -l app=minio -n minio --timeout=60s
kubectl apply -f minio_initiate_task.yaml -n minio
@REM kubectl logs -n minio job/minio-bucket-init   

kubectl apply -f opensearch_secret.yaml -n opensearch
kubectl apply -f opensearch_configmap_common.yaml -n opensearch
kubectl apply -f opensearch.yaml -n opensearch

@REM tier 2

kubectl apply -f ./lldap/lldap.yaml -n lldap

kubectl apply -f airflow_secret.yaml -n airflow
kubectl apply -f airflow_rbac.yaml -n airflow
kubectl apply -f airflow_configmap_common.yaml -n airflow
kubectl apply -f airflow_initiate_task.yaml -n airflow
@REM kubectl logs -n airflow job/airflow-init
kubectl apply -f airflow_worker.yaml -n airflow
kubectl apply -f airflow.yaml -n airflow

@REM ---

@REM kubectl port-forward -n rdbms svc/postgres-metadata 5432:5432
@REM kubectl port-forward -n rdbms svc/postgres-ops 5431:5432
@REM kubectl port-forward -n minio svc/minio 9001:9001
@REM kubectl port-forward -n opensearch svc/opensearch-dashboard 5601:5601
@REM kubectl port-forward -n lldap svc/lldap 17170:17170
@REM kubectl port-forward -n airflow svc/airflow-api-server 8080:8080



kubectl logs -n rdbms statefulset.apps/postgres-metadata
kubectl logs -n rdbms statefulset.apps/postgres-ops
kubectl logs -n airflow deployment.apps/airflow-scheduler
kubectl logs -n lldap deployment.apps/lldap
kubectl logs -n ranger deployment.apps/ranger-admin
kubectl logs -n opensearch statefulset.apps/opensearch-cluster-manager
kubectl logs -n opensearch statefulset.apps/opensearch-data
kubectl logs -n opensearch statefulset.apps/opensearch-coordinator
kubectl logs -n opensearch deployment.apps/opensearch-dashboard

docker create --name ranger-temp apache/ranger:2.8.0

docker create --name ranger-temp apache/ranger-base:20260123-2-17    

docker cp ranger-temp:opt/ranger/admin/setup.sh .

docker cp ranger-temp:/home/ranger/scripts/ranger-admin-install.properties .

docker cp ranger-temp:opt/ranger/admin/ews/ranger-admin-services.sh .

docker cp ranger-temp:/home/ranger/scripts/create-ranger-services.py .

docker cp ranger-temp:opt/ranger/admin/install.properties .

docker cp ranger-temp:/home/ranger/scripts/download-ranger.sh .

docker run --rm --entrypoint /bin/bash apache/ranger:2.8.0 -c 'find /opt/ranger -maxdepth 2 -type d | sort'

docker run --rm --entrypoint /bin/bash apache/ranger:2.8.0 -c 'find /opt/ranger -name "db_setup.py"'

docker cp ranger-temp:/opt/ranger/ranger-2.8.0-admin/db_setup.py .

docker run --rm --entrypoint /bin/bash apache/ranger-base:20260123-2-17 -c 'mvn -version'


docker run --rm --entrypoint /bin/bash apache/ranger-custom-usersync:2.8.0 -c 'ls /usr/lib/ranger/ranger--usersync'

docker run --rm --entrypoint /bin/bash apache/ranger-custom-usersync:2.8.0 -c 'cat /usr/lib/ranger/ranger--usersync/install.properties'


docker run --rm -v ${PWD}:/work alpine/helm:3.18.6 template opensearch /work/charts/opensearch > rendered.yaml

docker run --rm -v "${PWD}:/chart" -w /chart alpine/helm:3.18.6 template opensearch . > rendered.yaml

docker run --rm -v "%cd%:/chart" -w /chart alpine/helm:3.18.6 template opensearch . > rendered.yaml