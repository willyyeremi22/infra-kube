docker build -f ./airflow/dockerfile.airflow_s3_fab -t apache/airflow:3.2.2-python3.14-s3-fab .
docker build -f ./airflow/dockerfile.airflow_s3_k8s -t apache/airflow:3.2.2-python3.14-s3-k8s .
docker build -f ./ranger/dockerfile.ranger_admin -t apache/ranger-custom-admin:2.8.0 . @REM 2 >&1 | Tee-Object -FilePath build.log
docker build -f ./ranger/dockerfile.ranger_usersync -t apache/ranger-custom-usersync:2.8.0 .

kubectl apply -f namespace.yaml

@REM tier 1

kubectl apply -f ./rdbms/postgresql-metadata.yaml -n rdbms
kubectl apply -f ./rdbms/postgresql-ops.yaml -n rdbms
kubectl wait --for=condition=ready pod -l app=postgres-metadata -n rdbms --timeout=60s

kubectl apply -f ./minio/minio.yaml -n minio
kubectl wait --for=condition=ready pod -l app=minio -n minio --timeout=60s
kubectl apply -f ./minio/minio_initiate_task.yaml -n minio
@REM kubectl logs -n minio job/minio-bucket-init   

kubectl apply -f ./openldap/openldap.yaml -n openldap
timeout /T 60 /nobreak

kubectl apply -f ./opensearch/opensearch_secret.yaml -n opensearch
kubectl apply -f ./opensearch/opensearch_configmap_common.yaml -n opensearch
kubectl apply -f ./opensearch/opensearch.yaml -n opensearch
kubectl wait --for=condition=ready pod -l app=opensearch-cluster-manager -n opensearch --timeout=60s
kubectl apply -f ./opensearch/opensearch_initiate_task.yaml -n opensearch
@REM kubectl logs -n opensearch job.batch/opensearch-init

@REM tier 2

kubectl apply -f ./airflow/airflow_secret.yaml -n airflow
kubectl apply -f ./airflow/airflow_rbac.yaml -n airflow
kubectl apply -f ./airflow/airflow_configmap_common.yaml -n airflow
kubectl apply -f ./airflow/airflow_initiate_task.yaml -n airflow
kubectl wait --for=condition=ready pod -l app=airflow-init -n airflow --timeout=60s
@REM kubectl logs -n airflow job/airflow-init
kubectl apply -f ./airflow/airflow_worker.yaml -n airflow
kubectl apply -f ./airflow/airflow.yaml -n airflow

@REM tier 3

kubectl apply -f ./ranger/ranger_admin.yaml -n ranger
kubectl wait --for=condition=ready pod -l app=ranger-admin -n ranger --timeout=60s
timeout /T 60 /nobreak
kubectl apply -f ./ranger/ranger_usersync.yaml -n ranger


@REM ---

@REM kubectl port-forward -n rdbms svc/postgres-metadata 5432:5432
@REM kubectl port-forward -n rdbms svc/postgres-ops 5431:5432
@REM kubectl port-forward -n minio svc/minio 9001:9001
@REM kubectl port-forward -n opensearch svc/opensearch-dashboard 5601:5601
@REM kubectl port-forward -n openldap svc/phpldapadmin 80:80
@REM kubectl port-forward -n airflow svc/airflow-api-server 8080:8080
@REM kubectl port-forward -n ranger svc/ranger-admin 6080:6080



kubectl logs -n rdbms statefulset.apps/postgres-metadata
kubectl logs -n rdbms statefulset.apps/postgres-ops
kubectl logs -n opensearch statefulset.apps/opensearch-cluster-manager
kubectl logs -n opensearch statefulset.apps/opensearch-data
kubectl logs -n opensearch statefulset.apps/opensearch-coordinator
kubectl logs -n opensearch deployment.apps/opensearch-dashboard
kubectl logs -n airflow deployment.apps/airflow-scheduler
kubectl logs -n lldap deployment.apps/lldap
kubectl logs -n ranger deployment.apps/ranger-admin
kubectl logs -n ranger deployment.apps/ranger-usersync


kubectl exec deploy/ranger-usersync -n ranger -- tail -n 300 "/usr/lib/ranger/ranger--usersync/logs/usersync-ranger-usersync-5948dfc7c-4t2bt-.log" > usersync-real.log

ldapsearch -x -H ldap://openldap.openldap.svc.cluster.local:389 -D "uid=ranger_service,ou=people,dc=example,dc=com" -w password -b "dc=example,dc=com"

kubectl run ldaptest --rm -it --image=alpine --restart=Never -- sh -c "apk add openldap-clients ldapsearch -x -H ldap://lldap.lldap.svc.cluster.local:3890 -D 'uid=ranger_service,ou=people,dc=example,dc=com' -w password -b 'ou=people,dc=example,dc=com' '(objectClass=person)'"





ldapsearch -x -D "uid=ranger_service,ou=people,dc=example,dc=com" -w password -b "ou=groups,dc=example,dc=com" "(objectClass=groupOfNames)"

ldapwhoami -x -D "uid=ranger_service,ou=people,dc=example,dc=com" -w password

ldapsearch -x -D "uid=ranger_service,ou=people,dc=example,dc=com" -w password -b "dc=example,dc=com"

ldapsearch -Y EXTERNAL -H ldapi:/// -b "cn=config" "(olcSuffix=*)" olcSuffix

ldapsearch -Y EXTERNAL -H ldapi:/// -b "olcDatabase={1}mdb,cn=config" olcAccess

ldapsearch -x -D "uid=ranger_service,ou=people,dc=example,dc=com" -w password -s base -b "" namingContexts

ldapsearch -x -D "uid=ranger_service,ou=people,dc=example,dc=com" -w password -b "uid=ranger_service,ou=people,dc=example,dc=com"

ldapsearch -x -D "uid=ranger_service,ou=people,dc=example,dc=com" -w password -b "ou=groups,dc=example,dc=com"


kubectl exec -it openldap-0 -n openldap -- sh

kubectl exec -it ranger-usersync-5948dfc7c-4t2bt -n ranger -- sh

kubectl exec -it -n ranger ranger-usersync-5948dfc7c-4t2bt -- grep -R "deltasync" /etc/ranger/usersync/conf

kubectl exec -it -n ranger ranger-usersync-5948dfc7c-4t2bt -- grep -R "uSNChanged" /etc/ranger/usersync/conf

kubectl exec -it deployment/ranger-usersync -n ranger -- ldapsearch

kubectl exec -it deployment/ranger-usersync -n ranger -- grep -Ei "ldap|search|found|sync|user|group|person|objectclass|error|exception" /usr/lib/ranger/ranger--usersync/logs/*.log

kubectl rollout restart deployment ranger-usersync -n ranger

kubectl exec -it -n ranger ranger-usersync-5f4645756c-pcd2p -- sh -c 'cat /usr/bin/ranger-usersync' > grep-result.log

kubectl exec -it -n ranger ranger-usersync-5948dfc7c-qkjjk -- sh -c 'curl -v http://ranger-admin.ranger.svc.cluster.local:6080' > grep-result.log

docker create --name ranger-temp apache/ranger:2.8.0

docker create --name ranger-temp apache/ranger-base:20260123-2-17    

docker cp ranger-temp:opt/ranger/admin/setup.sh .


docker run --rm --entrypoint /bin/bash apache/ranger:2.8.0 -c 'curl -v http://ranger-admin.ranger.svc.cluster.local:6080'

docker run --rm --entrypoint /bin/bash apache/ranger:2.8.0 -c 'find /opt/ranger -maxdepth 2 -type d | sort'

docker run --rm --entrypoint /bin/bash apache/ranger:2.8.0 -c 'find /opt/ranger -name "db_setup.py"'

docker cp charming_sinoussi:/usr/lib/ranger/ranger--usersync/entrypoint.sh .

docker run --rm --entrypoint /bin/bash apache/ranger-custom-admin:2.8.0 -c 'ls -l'


docker run --rm --entrypoint /bin/bash apache/ranger-custom-admin:2.8.0 -c 'cat /usr/lib/ranger/ranger--admin/bin/ranger-admin-services.sh'

docker cp jovial_heyrovsky:/usr/lib/ranger/ranger--admin/ews/ranger-admin-services.sh .


docker run --rm -v ${PWD}:/work alpine/helm:3.18.6 template opensearch /work/charts/opensearch > rendered.yaml

docker run --rm -v "${PWD}:/chart" -w /chart alpine/helm:3.18.6 template opensearch . > rendered.yaml

docker run --rm -v "%cd%:/chart" -w /chart alpine/helm:3.18.6 template opensearch . > rendered.yaml

docker run --rm --entrypoint /bin/bash lldap/lldap:2026-05-26 -c 'cat /app/bootstrap.sh'

docker run --rm --entrypoint /bin/bash apache/ranger-custom-usersync:2.8.0 -c 'cat /usr/lib/ranger/ranger--usersync/ranger-usersync-services.sh'

kubectl get pod ranger-admin-85b86fb99d-g7zf5 -n ranger -o jsonpath='{.status.containerStatuses[0].imageID}'
docker image inspect apache/ranger-custom-admin:2.8.0 --format='{{.Id}}'