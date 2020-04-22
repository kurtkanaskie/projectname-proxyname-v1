#! /bin/bash

while getopts o:e:p:d: option
do
case "${option}"
in
o) ORG=${OPTARG};;
e) ENVIRONMENT=${OPTARG};;
p) PROXY=${OPTARG};;
d) DEVELOPER_EMAIL=${OPTARG};;
esac
done

TMP_FILE="./_tmp_deps.json"

if [ -z "$ORG" ] || [ -z "$ENVIRONMENT" ] || [ -z "$PROXY" ] || [ -z "$DEVELOPER_EMAIL" ]
then
	echo All of -o ORG -e ENVIRONMENT -p PROXY -d DEVELOPER_EMAIL must be specified
	exit 1;
fi

echo deleteApp
apigeetool deleteApp -j -N -o kurtkanaskiecicd-eval --name ${PROXY}-${ENVIRONMENT} --email ${DEVELOPER_EMAIL}
echo deleteApp $?

echo deleteDeveloper
apigeetool deleteDeveloper -j -N -o kurtkanaskiecicd-eval --email ${PROXY}-${ENVIRONMENT}@any.com
echo deleteDeveloper $?

echo deleteProduct
apigeetool deleteProduct -j -N -o kurtkanaskiecicd-eval --productName ${PROXY}-${ENVIRONMENT}
echo deleteProduct $?

echo listdeployments
apigeetool listdeployments -j -N -o kurtkanaskiecicd-eval -n ${PROXY} > ${TMP_FILE}
echo listdeployments $?
for i in $(jq '.deployments | keys | .[]' ${TMP_FILE})
do 
	ENVIRONMENT=$(jq -r ".deployments[$i].environment" ${TMP_FILE})
	REV=$(jq -r ".deployments[$i].revision" ${TMP_FILE})
	echo undeploy $ENVIRONMENT $REV
	apigeetool undeploy -j -N -o kurtkanaskiecicd-eval -n ${PROXY} -e $ENVIRONMENT -r $REV
	echo undeploy $?
done

echo deleteProxy
apigeetool delete -j -N -o kurtkanaskiecicd-eval -n ${PROXY}
echo deleteProxy $?

echo deleteCache
apigeetool deleteCache -j -N -o kurtkanaskiecicd-eval --cache ${PROXY} -e ${ENVIRONMENT}
echo deleteCache $?

echo deleteKVMMap
apigeetool deleteKVMMap -j -N -o kurtkanaskiecicd-eval --mapName ${PROXY} -e ${ENVIRONMENT}
echo deleteKVMMap $?

echo deleteTargetServer
apigeetool deleteTargetServer -j -N -o kurtkanaskiecicd-eval --targetServerName ${PROXY} -e ${ENVIRONMENT}
echo deleteTargetServer $?
