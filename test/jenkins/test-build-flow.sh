#! /bin/bash

GIT_COMMIT=`date` 
GIT_BRANCH=origin/prod 
source ./set-edge-env-values.sh

PreviousRev=`./get-deployed-revision.sh`
echo PreviousRev=$PreviousRev

mvn install -P ${EdgeProfile} -Ddeployment.suffix=${EdgeDeploySuffix} -Dapigee.org=${EdgeOrg} -Dapigee.env=${EdgeEnv} -Dapi.northbound.domain=${EdgeNorthboundDomain} -Dapigee.username=${EdgeInstallUsername} -Dapigee.password=${EdgeInstallPassword} -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge -Dapigee.config.exportDir=target/test/integration -Dcommit='${GIT_COMMIT}' -Dbranch=${GIT_BRANCH} > /dev/null

echo mvn exit code $?

echo Forcing and error to simulate integration test failure.
cat foo

if [ $? -eq 1 ]
then
	echo ERROR
	PostRev=`./get-deployed-revision.sh`
	echo PostRev=$PostRev

	if test "$PreviousRev" == "$PostRev"
	then
		echo "WARNING: build failed and existing revision $PreviousRev is still deployed"
	else
		echo "WARNING: build failed reverting from $PostRev to $PreviousRev"
		./deploy-revision.sh $PreviousRev > /dev/null
		CurrentRev=`./get-deployed-revision.sh`
		echo "WARNING: Deployed version is confirmed to be: $CurrentRev"
	fi
else
	echo SUCCESS
fi
