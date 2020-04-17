# Project Specific Ping and Status API Template

This proxy demonstrates a simple design to demonstrate a full CI/CD lifecycle for an API Proxy including static and unit tests, build and deploy, integration tests, and API documentation for both Drupal and Integrated Portals.
It uses the Apigee provided plugins:
* Build and deploy: [apigee-edge-maven-plugin](https://github.com/apigee/apigee-deploy-maven-plugin)
* Configuration items, including specs: [apigee-config-maven-plugin](https://github.com/apigee/apigee-config-maven-plugin)
* Smartdocs for Drupal 7 and 8: [apigee-smartdocs-maven-plugin](https://github.com/apigee/apigee-smartdocs-maven-plugin)

## TL;DR
Clone the repository and add your Maven profile for your Apigee organization and environment.
* Then run the [Maven Commands - full build](#maven-commands---full-build).

## Disclaimer

This example is not an official Google product, nor is it part of an official Google product.

## Notice and License
[NOTICE](NOTICE) this material is copyright 2020, Google LLC. and [LICENSE](LICENSE) is under the Apache 2.0 license. This code is open source.

## Overview
The proxy has the following endpoints:
* GET /ping - response indicates that the proxy is operational
* GET /status - response indicates the the backend is operational

They can be used with Edge API Monitoring to send notifications when something is wrong.

## CI/CD Overview
Each proxy is managed as a single source code module that is self contained with the actual Apigee Edge proxy, config files for Edge Management API calls (e.g. KVMs, target servers), Open API Specification (OAS) and tests (status, unit, integration).

The key components enabling continuous integration are:
* Jenkins, GCP Cloud Build, Azure - build host
* Maven - builder
* npm, node - to run unit and integration tests
* Apickli - cucumber extension for RESTful API testing
* Cucumber - Behavior Driven Development
* JMeter - Performance testing

Basically, everything that Jenkins does using Maven and other tools can be done locally, either directly with the tool (e.g. jslint, cucumberjs) or via Maven commands. The sections below show how to do each.

## Git Commands
Align Git branches with org / env combinations, with master being the lowest level in lifecycle (e.g. test), then use pull requests to merge to downstream branches reflecting higher level deployments (e.g. prod).

### Master Branch (lowest environment)
* git checkout -b prod
* git push origin prod
* git checkout master
* `mvn -P test install ...` as per [Maven Commands - full build](#maven-commands---full-build).

### Feature Branches
* git checkout -b feature/jira1 --- (MAKE changes for feature/jira1)
* `mvn -P test install -Ddeployment.suffix=jira1 ...` as per [Maven Commands - full build](#maven-commands---full-build).

#### Test via Jenkins
* git commit -am  "Added changes for feature1"
* git push origin feature/jira1

If the build succeeds you're ready to merge into the master branch.

#### Merge Branch to Master
##### Pull Request via Browser
* Go to repo and create pull request from feature/jira1 to master
* Comment on pull request
* Do the merge pull request "Create a merge commit" or use command line

##### Pull Request via command line
* git checkout master
* git merge --no-ff feature/jira1
* git push

Clean up feature branch
* git branch -d feature/jira1
* git push origin --delete feature/jira1

Or using this:
* git push origin :feature/jira1

#### Update local Master
* git checkout master
* git pull

### Merge Master Branch to Higher Environment Branches (e.g. prod)
* git checkout prod
* git pull
* git merge --no-ff master
* git push
* git checkout master

## Jenkins Overview
The Jenkins build server runs Maven with these commands.

Set Environment variables via script
```
./set-edge-env-values.sh > edge.properties
```
This allows a single build project to be used for each of the branches including feature branches.

```
install -P${EdgeProfile} -Ddeployment.suffix=${EdgeDeploySuffix} \
 -Dapigee.org=${EdgeOrg} -Dapigee.env=${EdgeEnv} -Dapi.northbound.domain=${EdgeNorthboundDomain} \
 -Dapigee.username=${EdgeInstallUsername} -Dapigee.password=${EdgeInstallPassword} \
 -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge -Dapigee.config.exportDir=target/test/integration \
 -Dcommit=${GIT_COMMIT} -Dbranch=${GIT_BRANCH}
```

Note the use of `-deployment.suffix=`. That is so the build and deploy to Apigee creates a separate proxy with a separate basepath to allow independent feature development. Your proxy will show up with a name (e.g. pingstatus-${user.name}v1) and basepath (e.g. /pingstatus/${user.name}v1).

For other environments (e.g. test, prod) the `-deployment.suffix=` is set blank, so the build puts the proxy into the final form with the final basepath (e.g. pingstatus-v1, /pingstatus/v1).
```
mvn -P test clean install  -Ddeployment.suffix= -Dapi.testtag=@intg,@health
```

NOTE: If you get a strange error from Maven about replacement `named capturing group is missing trailing '}'` there is something wrong with your options or replacements settings. Use '-X' and look for unfulfilled variables (e.g. ${apigee.username}).

In addition to "replacing" that string the "process-resources" phase does inline replacement to support the "feature" proxy.
The most important change is to the `test/apickli/config/config.json` file which changes the basepath for the proxy so the tests go to the correct feature proxy in Apigee.
Other changes are done on resources for the org, such as API products, Apps and Developers to profide artifacts for testing in each org / env.

## Local Configuration
In each source directory there is a `package.json` file that holds the required node packages.

* [Install Maven](https://maven.apache.org/install.html)
* [Install Node](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) (optional, it's done by maven)

Set your $HOME/.m2/settings.xml profile information for local builds.
Example:
```
<?xml version="1.0"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                 https://maven.apache.org/xsd/settings-1.0.0.xsd">
    <profiles>
        <profile>
            <id>test</id>
            <!-- These are also the values for environment variables used by set-edge-env-values.sh for Jenkins -->
            <properties>
                <EdgeOrg>yourorgname</EdgeOrg>
                <EdgeEnv>yourenv</EdgeEnv>
                <EdgeUsername>yourusername@exco.com</EdgeUsername>
                <EdgePassword>yourpassword</EdgePassword>
                <EdgeNorthboundDomain>yourourgname-yourenv.apigee.net</EdgeNorthboundDomain>
                <EdgeAuthtype>oauth</EdgeAuthtype>
            </properties>
        </profile>
        ...
    </profiles>
</settings>
```
### Initial build and deploy
`mvn -P test install ...` as per [Maven Commands - full build](#maven-commands---full-build).


## Maven Commands - full build
Replacer copies and replaces the resources dir into the target. Note use of -Dapigee.config.dir option.

### Maven all at once
* mvn -P test install -Ddeployment.suffix= -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge -Dapigee.config.exportDir=target/test/integration -Dapigee.smartdocs.config.options=update

### Cloud Build all at once
* cloud-build-local --dryrun=true --substitutions=BRANCH_NAME=local,COMMIT_SHA=none .
* cloud-build-local --dryrun=false --substitutions=BRANCH_NAME=local,COMMIT_SHA=none .

## Maven Pipeline Steps
Builds use Maven which runs via configurations in a pom file (pom.xml). Maven [default build lifecycle](https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html#Lifecycle_Reference) phases and usage:
* **validate**: lint Javascript, Apigeelint
* **process-resources**: copy resources and run replacements
* **package**: package compiled sources into the distributable format (proxy.zip)
* **verify**: caches, keyvalumaps, targetservers
* **install**: install and deploy the package to a local repository

The following "outer" commands run all phases up to and including that phase, while the "inner" commands run independently and can be used for a step-by-step pipeline.

mvn **validate**
* mvn jshint:lint
* mvn frontend:install-node-and-npm
* mvn frontend:npm
* mvn frontend:npm@apigeelint
* mvn frontend:npm@unit


mvn -P cicd-test **process-resources** -Ddeployment.suffix= -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge
* mvn -P cicd-test resources:copy-resources@copy-resources
* mvn -P cicd-test replacer:replace -Ddeployment.suffix= -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge


mvn -P cicd-test **package** -Ddeployment.suffix=
* mvn -P cicd-test apigee-enterprise:configure


mvn -P cicd-test **verify** -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge
* mvn -P cicd-test apigee-config:caches -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge
* mvn -P cicd-test apigee-config:keyvaluemaps -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge
* mvn -P cicd-test apigee-config:targetservers -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge


mvn -P cicd-test **install** -Ddeployment.suffix= -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge -Dapigee.config.exportDir=target/test/integration -Dskip.specs=true
* mvn -P cicd-test apigee-config:userroles -Ddeployment.suffix= -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge
* mvn -P cicd-test apigee-config:apiproducts -Ddeployment.suffix= -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge
* mvn -P cicd-test apigee-config:developers -Ddeployment.suffix= -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge
* mvn -P cicd-test apigee-config:apps -Ddeployment.suffix= -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge
* mvn -P cicd-test apigee-config:exportAppKeys -Ddeployment.suffix= -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge -Dapigee.config.exportDir=target/test/integration
* mvn -P cicd-test apigee-enterprise:deploy -Ddeployment.suffix=
* mvn -P cicd-test frontend:npm@integration

Do docs last (NOTE: specs will run before integration tests by default, hence the use of `-Dskip.specs=true` in install phase above)
* mvn -P test apigee-smartdocs:apidoc -Dapigee.smartdocs.config.options=update
* mvn -P cicd-test apigee-config:specs -Ddeployment.suffix= -Dapigee.config.options=update -Dapigee.config.dir=target/resources/edge

## TODO
* Test feature Branches
* Incorporate App and Developer UUIDs into userrole
*
