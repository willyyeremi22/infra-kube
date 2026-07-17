set NAMESPACE=ranger
set POD=ranger-usersync-5f4645756c-bmdkn


set LOGFILE=%~dp0logs.log
(kubectl logs "%POD%" -n "%NAMESPACE%") > "%LOGFILE%" 2>&1
@REM (kubectl logs "%POD%" -n "%NAMESPACE%" --previous) > "%LOGFILE%" 2>&1

set LOGFILE=%~dp0describe_pod.log
(kubectl describe pod "%POD%" -n "%NAMESPACE%") > "%LOGFILE%" 2>&1

set LOGFILE=%~dp0get_pods.log
(kubectl get pods -n "%NAMESPACE%" -o wide) > "%LOGFILE%" 2>&1

