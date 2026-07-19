set NAMESPACE=ranger
set POD=ranger-usersync-5948dfc7c-cmt9h

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TIMESTAMP=%%i

set LOGFILE=%~dp0\logs\logs_%TIMESTAMP%.log
(kubectl logs "%POD%" -n "%NAMESPACE%") > "%LOGFILE%" 2>&1
@REM (kubectl logs "%POD%" -n "%NAMESPACE%" --previous) > ./logs/"%LOGFILE%" 2>&1

set LOGFILE=%~dp0\describe_pod\describe_pod_%TIMESTAMP%.log
(kubectl describe pod "%POD%" -n "%NAMESPACE%") > "%LOGFILE%" 2>&1

set LOGFILE=%~dp0\get_pods\get_pods_%TIMESTAMP%.log
(kubectl get pods -n "%NAMESPACE%" -o wide) > "%LOGFILE%" 2>&1



