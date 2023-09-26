#
# Module manifest for module 'guided-setup'
#
# Generated by: Code Dx
#
# Generated on: 7/21/2022
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'guided-setup'

# Version number of this module.
ModuleVersion = '1.16.0'

# Supported PSEditions
CompatiblePSEditions = @('Core')

# ID used to uniquely identify this module
GUID = '26bcb7a5-2ec2-4d3e-bd19-b80a96dacd6b'

# Author of this module
Author = 'Code Dx'

# Company or vendor of this module
CompanyName = 'Synopsys'

# Copyright statement for this module
Copyright = '(c) 2022 Code Dx. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This module includes a framework for installing an application on a Kubernetes cluster using a setup wizard based on a directed graph.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.0.0'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
#
# Autogenerate with these commands:
#   $files = (Get-ChildItem -LiteralPath './functions' -Recurse -Include '*.ps1','*.psm1') + (Get-ChildItem './guided-setup.psm1')
#   [string]::join(',',($files | ForEach-Object { Select-String -input $_ -pattern '^function\s([^(]+)(?:\s|\()' -allmatches | ForEach-Object { "'$($_.matches.groups[1].value)'" } } | Sort-Object))
#
FunctionsToExport = @('Add-HelmRepo','Add-KeystoreAlias','Add-ResourceLabel','Add-Step','Add-StepTransition','Add-StepTransitions','Clear-HostStep','Convert-Base64','ConvertTo-Map','ConvertTo-PsonMap','ConvertTo-PsonStringArray','ConvertTo-YamlIntArray','ConvertTo-YamlMap','ConvertTo-YamlMap','ConvertTo-YamlStringArray','Copy-DBBackupFiles','Copy-K8sItem','Edit-ResourceJsonPath','Edit-ResourceStrategicPatch','Format-KeyValueAssignment','Format-NodeSelector','Format-PodTolerationNoScheduleNoExecute','Format-ResourceLimitRequest','Get-AppCommandPath','Get-CertificateFromCsr','Get-CommonName','Get-CsrSignerNameLegacyUnknown','Get-DatabaseUrl','Get-DockerImageParts','Get-HelmChartFullname','Get-HelmReleaseAppVersion','Get-HelmReleaseHistory','Get-HelmValues','Get-HelmVersionMajorMinor','Get-IPv4AddressList','Get-KeystorePasswordEscaped','Get-KeytoolJavaSettings','Get-KeytoolJavaSpec','Get-KubectlClientVersion','Get-KubectlContext','Get-KubectlContexts','Get-KubectlDryRunParam','Get-KubectlServerSemanticVersion','Get-KubectlServerVersion','Get-KubectlServerVersionMajor','Get-KubectlServerVersionMinor','Get-KubectlServerVersionNumber','Get-KubectlVersion','Get-KubernetesEndpointsPort','Get-KubernetesPort','Get-MasterFilePosAfterReset','Get-ResourceDirectoryPath','Get-SecretFieldValue','Get-SemanticVersionComponents','Get-ServiceAccountName','Get-TrustedCaCertAlias','Get-VirtualCpuCountFromReservation','Import-TrustedCaCert','Import-TrustedCaCerts','Invoke-GitClone','Invoke-GuidedSetup','Invoke-HelmCommand','New-Certificate','New-CertificateConfigMap','New-CertificateConfigMapResource','New-CertificateSecret','New-CertificateSecretResource','New-ConfigMap','New-ConfigMapResource','New-Csr','New-CsrApproval','New-CsrResource','New-Database','New-DockerImagePullSecretResource','New-GenericSecret','New-GenericSecretResource','New-GitRepository','New-HelmCommand','New-HelmControllerChartSource','New-HelmControllerConfigMapValues','New-HelmControllerGitSource','New-HelmOperatorChartSource','New-HelmOperatorConfigMapValues','New-HelmOperatorGitSource','New-HelmRelease','New-HelmRepository','New-ImagePullSecret','New-Namespace','New-NamespacedResource','New-NamespacedResourceFromYaml','New-NamespaceResource','New-PriorityClass','New-PriorityClassResource','New-ResourceFile','New-SealedSecret','New-SealedSecretFile','New-SecretResourceFile','Read-HostChoice','Read-HostEnter','Read-HostSecureText','Read-HostText','Remove-ConfigMap','Remove-CsrResource','Remove-Database','Remove-KeystoreAlias','Remove-KubernetesJob','Remove-KubernetesPvc','Remove-NamespacedResource','Remove-Pod','Remove-PriorityClass','Remove-ResourceLabel','Remove-Secret','Remove-VeleroBackupSchedule','Set-CustomResourceDefinitionResource','Set-DeploymentReplicas','Set-GuidedSetupModulePreferences','Set-K8sResource','Set-KeystorePassword','Set-KubectlContext','Set-KubectlFromFilePath','Set-NamespaceLabel','Set-NonNamespacedResource','Set-Replicas','Set-ResourceDirectory','Set-StatefulSetReplicas','Split-DockerName','Split-DockerRepo','Start-SlaveDB','Stop-SlaveDB','Test-CertificateSigningRequestV1Beta1','Test-CertificateSigningRequestV1Beta1','Test-ClusterInfo','Test-ConfigMap','Test-CsrResource','Test-CurrentKubeContext','Test-Database','Test-Deployment','Test-DeploymentLabel','Test-EmailAddress','Test-HelmRelease','Test-IsBlacklisted','Test-IsCore','Test-IsElevated','Test-IsValidParameterValue','Test-KeystoreAlias','Test-KeystorePassword','Test-KeyToolCertificate','Test-KubernetesJob','Test-MinPsMajorVersion','Test-Namespace','Test-NamespacedResource','Test-NonNamespacedResource','Test-Pod','Test-PriorityClass','Test-ResourceApiVersion','Test-Secret','Test-Service','Test-SetupKubernetesVersion','Test-StatefulSet','Test-VeleroBackupSchedule','Wait-AllRunningPods','Wait-Deployment','Wait-JobSuccess','Wait-ReplicasReady','Wait-RunningPod','Wait-StatefulSet','Write-ErrorMessageAndExit','Write-HostSection','Write-ImportantNote','Write-StepGraph')

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
#
# Autogenerate with these commands:
#   $location = get-location
#   $files = @("'./demo/demo-link.txt'") + (Get-ChildItem -LiteralPath ./functions -Recurse -Include '*.ps1' -Attributes 'hidden','normal' | % { [io.path]::GetRelativePath($location, $_.fullname) } | ForEach-Object { "'$_'" } )
#   [string]::join(',', $files)
#
FileList = @('./demo/demo-link.txt','functions/docker.ps1','functions/helm.ps1','functions/input.ps1','functions/k8s.ps1','functions/keytool.ps1','functions/mariadb.ps1','functions/resource.ps1','functions/step.ps1','functions/utils.ps1','functions/velero.ps1')

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

	PSData = @{

		# Tags applied to this module. These help with module discovery in online galleries.
		# Tags = @()

		# A URL to the license for this module.
		LicenseUri = 'https://github.com/codedx/guided-setup/blob/main/LICENSE'

		# A URL to the main website for this project.
		ProjectUri = 'https://github.com/codedx/guided-setup'

		# A URL to an icon representing this module.
		# IconUri = ''

		# ReleaseNotes of this module
		# ReleaseNotes = ''

		# Prerelease string of this module
		# Prerelease = ''

		# Flag to indicate whether the module requires explicit user acceptance for install/update/save
		# RequireLicenseAcceptance = $false

		# External dependent modules of this module
		# ExternalModuleDependencies = @()

	} # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

