#! /bin/bash

# Deploy EdgeRevision if build fails
# Needs to run after set-edge-env-values.sh and injecting env variables so EdgeEnv and EdgeDeploySuffix is correct.
# Expects EdgeOrg, EdgeEnv, EdgeProxy and PreviousRevision env variables.

# Deploy $PreviousRevision provided as environment variable in Jenkins build step
PreviousRevision=$1
echo PreviousRevision=$PreviousRevision
curl -s -X POST -u $EdgeInstallUsername:$EdgeInstallPassword --header "Content-Type: application/x-www-form-urlencoded" "https://api.enterprise.apigee.com/v1/o/$EdgeOrg/e/$EdgeEnv/apis/$EdgeProxy/revisions/$PreviousRevision/deployments?override=true"
