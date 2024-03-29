## Overview

This reference implementation describes how to use the [guided-setup PowerShell Core module](https://www.powershellgallery.com/packages?q=guided-setup). The demo files show how the guided setup can assist with the configuration and deployment of [Bitnami's MariaDB Helm chart](https://github.com/bitnami/charts/tree/master/bitnami/mariadb). 

This MariaDB guided setup and deployment script provide the following benefits:

- asserts prerequisites
- creates Kubernetes (K8s) Secret dependency for MariaDB passwords
- avoids using the same password for root and replicator database accounts
- creates K8s ConfigMap dependency for MariaDB options
- configures binary log expiration when using replication
- configures optional character set, collation, and table name case
- generates resource files or orchestrates helm deployment

>Note: You do not need to cover every possible deployment configuration with a guided setup and related deployment script.

You can start the setup by [installing PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell) and running this command: `pwsh ./guided-setup.ps1`.

![Welcome](images/welcome.png)

The reference implementation has two main parts. The first is the guided setup, a series of screens that gather the desired deployment configuration from a user. The second is a setup script that takes the setup responses and either orchestrates the deployment by running helm or stops short of running helm by producing required helm values and K8s resource files. The reference implementation lets the user decide the deployment method.

![DeploymentMethod](images/deployment-method.png)

## Guided Setup - Part One

The [guided-setup.ps1](guided-setup.ps1) file provides the starting point. It is a wrapper. The first step dot sources the [.install-guided-setup-module.ps1](.install-guided-setup-module.ps1) to install a specific guided-setup module version. The next step dot sources the [.guided-setup.ps1](.guided-setup.ps1) file, which is the main file that establishes the directed graph of configuration steps and invokes the guided setup.

The .guided-setup.ps1 file has multiple parts. The [using module](.guided-setup.ps1#L8) statement imports a specific version of the guided-setup module (it should reference the same version specified in .install-guided-setup-module.ps1). It allows you to reference PowerShell content from the guided-setup module. Files containing guided setup steps then get included via [dot sourcing](.guided-setup.ps1#L34). The next phase [adds each step](.guided-setup.ps1#L53) to the directed graph. With the steps added, the next step is to establish [step transitions](.guided-setup.ps1#L56). Step transitions define how the user can move between steps. Define transitions to optional steps first to allow those steps to run conditionally. The main setup starts by running the [Invoke-GuidedSetup](.guided-setup.ps1#L84) function.

## Steps

Each configuration step should derive from a base [Step](core/steps/step.ps1) that derives from the module's [GuidedSetupStep](../guided-setup.psm1#L873). The base step should accept a [ConfigInput](core/steps/config.ps1) parameter that will include your setup parameters.

The [core/steps](core/steps) directory includes files with MariaDB-related guided setup steps. For example, the [credential.ps1](core/steps/credential.ps1) contains the steps required to gather the root and replicator account passwords. Specifying the latter password is required when using MariaDB's replication feature, so the [CanRun](core/steps/credential.ps1#L70) function determines whether the replication account password screen appears. It uses a [helper method](core/steps/config.ps1#L28) to determine whether replication is enabled, something the user indicates on the [ReplicaCount](core/steps/replication.ps1) screen.

## Prerequisite Step

An important step is testing whether prerequisites have been met. The [Prerequisites](core/steps/prereq.ps1#L1) step uses the [Test-SetupPreqs](core/setup/prereqs.ps1#L1) function to check prerequisites. It uses the same function invoked by the [guided-setup-check-prereqs.ps1](guided-setup-check-prereqs.ps1) script that can be run standalone.

![Prerequisites](images/prerequisites.png)

## Questions

The guided-setup module includes multiple question types, derived from [Question](../guided-setup.psm1#L604). The base question has parameters that affect how the response is gathered. For example, an answer can be masked by setting [$isSecure](../guided-setup.psm1#L612) to $true.

The [ConfirmationQuestion](../guided-setup.psm1#L675) requests an input that must be matched when entered a second time. You can use it to gather passwords when masking a response. The [IntegerQuestion](../guided-setup.psm1#L708) lets you request an integer response that falls between a minimum and maximum value. The [PathQuestion](../guided-setup.psm1#L755) lets you request a path to a file or directory, validating whether the filesystem item exists. The [CertificateFileQuestion](../guided-setup.psm1#L790) question derives from PathQuestion and validates the response as a certificate file. You can use the [MultipleChoiceQuestion](../guided-setup.psm1#L843) for responses selected from a list of valid choices. A yes/no response can be fetched using the [YesNoQuestion](../guided-setup.psm1#L865).

## Last Step

The guided setup ends with a [Finish](core/steps/summary.ps1#L16) step that prepares setup.ps1 script parameters according to the guided setup responses.

![Finish](images/finish.png)

The [setup.ps1](core/setup.ps1) file can invoke helm or create the Helm and K8s resource files so you can run helm on your own. The [$resourceFilesOnly](core/setup.ps1#L32) parameter determines the deployment mode.

## Deployment Script - Part Two

Specifying MariaDB options like binary log file expiration requires appending settings to the default MariaDB configuration. The [options.ps1](core/steps/options.ps1) file includes the [MariaDBOptions](core/steps/options.ps1#L1) step, asking whether default MariaDB options will be used, or if the user wants to specify a specific character set, collation, and table name option. The [setup](core/setup) directory contains files upon which [setup.ps1](core/setup.ps1) depends, and the resources.ps1 file includes the [New-MariaDBOptionConfigMap](core/setup/resources.ps1#L27) function that helps you specify optional MariaDB options.

A guided setup implementation does not need to cover every deployment configuration. For example, the Bitnami MariaDB Helm chart includes many parameters not covered by the reference implementation. The [$extraValuesFiles](core/setup.ps1#L26) parameter accepts additional helm values files outside the scope of the guided setup. Similarly, you can include any additional [setup.ps1](core/setup.ps1) parameters that are outside the scope of your guided setup (e.g., the `primaryName` and `replicaName` setup.ps1 parameters).

![Parameters](images/parameters.png)

## Pester Tests

You can use [Pester](https://pester.dev/) to test the guided setup by simulating a user at the keyboard. The [guided-setup-tests.ps1](test/guided-setup-tests.ps1) file includes example tests that depend on [mock.ps1](test/mock.ps1) and [pass.ps1](test/pass.ps1). You can run the test by invoking this command: `pwsh ./test/guided-setup-tests.ps1`. Note that you must have previously installed the guided-setup module either indirectly by running the guided setup or by directly running the .install-guided-setup-module.ps1 script (with pwsh ./.install-guided-setup-module.ps1).

![Tests](./images/tests.png)

## Graph Visualization

You can visualize the guided setup graph by setting $DebugPreference='Continue' to generate the following at the start of the setup:

```
digraph G {
BinaryLogExpiration -> RootPwd;
WorkDir -> Namespace;
RootPwd -> ReplicationPwd;
RootPwd -> MariaDBOptions;
ReleaseName -> ReplicaCount;
PrequisitesNotMet -> Abort;
DeploymentMethod -> Prerequisites;
TableNameCase -> Finish;
Collation -> TableNameCase;
ChooseContext -> HandleNoContext;
ChooseContext -> SelectContext;
ReplicationPwd -> MariaDBOptions;
ReplicaCount -> BinaryLogExpiration;
ReplicaCount -> RootPwd;
SelectContext -> PrequisitesNotMet;
SelectContext -> WorkDir;
Welcome -> DeploymentMethod;
HandleNoContext -> Abort;
Namespace -> ReleaseName;
Prerequisites -> PrequisitesNotMet;
Prerequisites -> ChooseContext;
CharacterSet -> Collation;
MariaDBOptions -> CharacterSet;
MariaDBOptions -> Finish;
}
```

You can visualize the resulting graph at [GraphvizOnline](https://dreampuf.github.io/GraphvizOnline). You can paste the [debug output](.guided-setup.ps1#L78) into the display's left side to see the graph on the right. 

![Guided Setup Steps](./images/guided-setup.svg)

You can also use GraphvizOnline to view the path a user took in the guided setup by visualizing the graph.path file produced by the [Write-StepGraph](.guided-setup.ps1#L86) function. A blue highlight will show the user's path through the setup.

![Guided Setup Steps Visited](./images/guided-setup-visited.svg)
