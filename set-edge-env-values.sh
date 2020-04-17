#! /bin/bash

# IMPORTANT NOTES:
# Hard coded for EdgeOrg and EdgeProxyPrefix and EdgeProxySuffix 
# Create EdgeProxy = "${EdgeProxyPrefix}${EdgeDeploySuffix}${EdgeProxySuffix}"
# Expects envs and profiles for "test" and "prod" in pom.xml

# If GIT_BRANCH is master or feature, set EdgeEnv to "test"
# Else If GIT_BRANCH is feature, set EdgeDeploySuffix to featurename
# Else If GIT_BRANCH is prod, set EdgeEnv to "prod"
# /origin/master
# /origin/feature/jira1
# /origin/prod

# echo BRANCH: $GIT_BRANCH
# Test via:
# GIT_BRANCH=origin/master set-edge-env-values.sh kurtkanaskiecicd-eval projectname-proxyname- v1
# GIT_BRANCH=origin/prod set-edge-env-values.sh kurtkanaskiecicd-eval projectname-proxyname- v1
# GIT_BRANCH=origin/feature/1 set-edge-env-values.sh kurtkanaskiecicd-eval projectname-proxyname- v1

# Should have better arg management
export EdgeOrg=$1
EdgeProxyPrefix=$2
EdgeProxySuffix=$3

# EdgeProxy="${EdgeProxyPrefix}${EdgeDeploySuffix}${EdgeProxySuffix}"

EdgeProfile="" 
EdgeDeploySuffix="" 

if [[ "$GIT_BRANCH" == origin/master ]]
then
	export EdgeProfile="test"
	export EdgeEnv="test"

elif [[ "$GIT_BRANCH" == origin/feature/* ]]
then
	export EdgeProfile="test"
	export EdgeEnv="test"
	# Get the feature name, tmp removes up to and including first /, do that again to get suffix
	tmp=${GIT_BRANCH#*/}
	export EdgeDeploySuffix=${tmp#*/}

elif [[ "$GIT_BRANCH" == origin/prod ]]
then
	export EdgeEnv="prod"
	export EdgeProfile="prod"
else
	echo GIT_BRANCH \"$GIT_BRANCH\" not found.
	exit 1
fi

export EdgeNorthboundDomain=$EdgeOrg-$EdgeEnv.apigee.net

# ConfigChanges=`git diff --name-only HEAD HEAD~1 | grep "edge.json"`
ConfigChanges=`git diff --name-only HEAD HEAD~1 | grep "resources"`
if [[ $? -eq 0 ]]
then
	export EdgeConfigOptions="update"
else
	export EdgeConfigOptions="none"
fi

export EdgeProxy="${EdgeProxyPrefix}${EdgeDeploySuffix}${EdgeProxySuffix}"

# Expect to redirect output from this script to an "edge.properties" file.
echo EdgeOrg=$EdgeOrg
echo EdgeEnv=$EdgeEnv
echo EdgeNorthboundDomain=$EdgeNorthboundDomain
echo EdgeProfile=$EdgeProfile 
echo EdgeDeploySuffix=$EdgeDeploySuffix 
echo EdgeConfigOptions=$EdgeConfigOptions
echo EdgeProxy=$EdgeProxy
