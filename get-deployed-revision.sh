#! /bin/bash

# Get currently deployed revision if build fields, so we can redeploy
# Needs to run after set-edge-env-values.sh and Injecting env variables so EdgeEnv and EdgeDeploySuffix is correct.
# Expects EdgeOrg, EdgeEnv and EdgeProxy env variables.

# Get EdgeDeployedRevision
EdgeRevision=`curl -s -u $EdgeInstallUsername:$EdgeInstallPassword https://api.enterprise.apigee.com/v1/o/$EdgeOrg/e/$EdgeEnv/apis/$EdgeProxy/deployments | grep '^    "name"' | cut -d '"' -f 4`
export EdgeRevision=$EdgeRevision

echo $EdgeRevision
