<#PSScriptInfo
.VERSION 1.0.0
.GUID bed24bcf-8230-4909-8619-50d5bc381721
.AUTHOR Guided Setup Author
.DESCRIPTION Prepares helm and K8s resource files and optionally runs deployment
#>

param (
	[string]   $workDir = "$HOME/.k8s-mariadb",
	
	[string]   $kubeContextName='dev',
	
	[string]   $namespace = "db",
	[string]   $releaseName = "mariadb",

	[int]      $replicaCount = 1,
	[int]      $binaryLogExpirationSeconds = 5,

	[string]   $rootPwd = ([guid]::newguid().guid.replace('-','')),
	[string]   $replicatorPwd = ([guid]::newguid().guid.replace('-','')),

	[string]   $characterSet = 'UTF8',
	[string]   $collation = 'utf8_general_ci',
	[int]      $lowerCaseTableNames = 0,

	[string[]] $extraValuesFiles = @(),

	[int]      $helmDeployWaitTimeSeconds = 600,
	[string]   $primaryName = 'primary',
	[string]   $replicaName = 'secondary',

	[switch]   $resourceFilesOnly
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

Set-PSDebug -Strict

### Import dependencies
'../.install-guided-setup-module.ps1', # install currently required guided-setup version
'./setup/validate.ps1',
'./setup/directory.ps1',
'./setup/resources.ps1',
'./setup/helm.ps1' | ForEach-Object {
	$path = join-path $PSScriptRoot $_
	if (-not (Test-Path $path)) {
		Write-Error "Unable to find file script dependency at $path. Please download all files and rerun the downloaded copy of this script."
	}
	. $path
}

### parameter validation
Write-Verbose 'Validating script parameters...'
$prereqMessages = @()
if (-not (Test-SetupParams ` ([ref]$prereqMessages) `
		'workDir','kubeContextName','namespace','releaseName','rootPwd','replicatorPwd','characterSet','collation' `
		'replicaCount','binaryLogExpirationSeconds','helmDeployWaitTimeSeconds' `
		$rootPwd `
		$replicatorPwd `
		$replicaCount `
		$lowerCaseTableNames `
		$workDir `
		$extraValuesFiles)) {
	Write-Error ([string]::join("`n", $prereqMessages))
}

### work directory config
Write-Verbose 'Configuring work directory...'
New-SetupWorkDirectory $workDir $namespace $releaseName

### namespace config
Write-Verbose 'Configuring namespace...'
New-MariaDBNamespace $namespace -resourceFileOnly:$resourceFilesOnly

### K8s secret config
Write-Verbose 'Configuring MariaDB credential K8s Secret...'
$dbCredentialsSecretName = 'db-credentials'
New-MariaDBCredentialSecret $namespace $dbCredentialsSecretName $rootPwd $replicatorPwd -resourceFileOnly:$resourceFilesOnly

### K8s configmap config
$dbOptionsConfigMapName = 'db-config'
Write-Verbose 'Configuring MariaDB options K8s ConfigMap...'
New-MariaDBOptionConfigMap $namespace $dbOptionsConfigMapName	$characterSet $collation $lowerCaseTableNames $binaryLogExpirationSeconds -resourceFileOnly:$resourceFilesOnly

### helm values config
$valuesFile = './helm-values.yaml'
Write-Verbose 'Generating helm values file...'
New-MariaDBValuesFile $dbCredentialsSecretName $dbOptionsConfigMapName $primaryName $replicaName $replicaCount $valuesFile

### gather all values files
$valuesPaths = @((Get-ChildItem $valuesFile))
$extraValuesFiles | ForEach-Object {
	$valuesPaths += (Get-ChildItem $_)
}

if ($resourceFilesOnly) {

	### Save recommended helm install/upgrade command
	Write-Verbose 'Generating helm command...'
	New-HelmCommand `
		$namespace `
		$releaseName `
		'bitnami/mariadb' `
		$valuesPaths

	Write-Verbose 'Done'
	return
}

### configure helm repository
Write-Verbose 'Configuring helm repo...'
Add-HelmRepo 'bitnami' 'https://charts.bitnami.com/bitnami'

### invoking helm
Write-Verbose 'Invoking helm...'
Invoke-HelmCommand 'MariaDB' `
	$helmDeployWaitTimeSeconds `
	$namespace `
	$releaseName `
	'bitnami/mariadb' `
	$valuesPaths

### waiting for statefulsets, showing deployment progress
$statefulSetName = $releaseName
if ($releaseName -ne 'mariadb') {
	$statefulSetName = "$releaseName-mariadb"
}
if ($replicaCount -gt 0) {
	Wait-StatefulSet "StatefulSet: $primaryName" $helmDeployWaitTimeSeconds $namespace "$statefulSetName-$primaryName" 1
	Wait-StatefulSet "StatefulSet: $replicaName" $helmDeployWaitTimeSeconds $namespace "$statefulSetName-$replicaName" $replicaCount
} else {
	Wait-StatefulSet "StatefulSet: $releaseName" $helmDeployWaitTimeSeconds $namespace $statefulSetName 1
}