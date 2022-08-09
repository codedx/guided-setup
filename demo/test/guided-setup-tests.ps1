using module @{ModuleName='Guided-Setup'; RequiredVersion='1.5.0' }

Import-Module 'pester' -ErrorAction SilentlyContinue
if (-not $?) {
	Write-Host 'Pester is not installed, so this test cannot run. Run pwsh, install the Pester module (Install-Module Pester), and re-run this script.'
	exit 1
}

$location = join-path $PSScriptRoot '..'
push-location ($location)

'./test/mock.ps1',
'./test/pass.ps1',
'core/setup/prereqs.ps1' | ForEach-Object {
	Write-Debug "'$PSCommandPath' is including file '$_'"
	$path = join-path $location $_
	if (-not (Test-Path $path)) {
		Write-Error "Unable to find file script dependency at $path. Please download the entire GitHub repository and rerun the downloaded copy of this script."
	}
	. $path | out-null
}

$DebugPreference = 'Continue'

function Test-SetupParameters([string] $testScriptPath, [string] $runSetupPath, [string] $workDir, [string] $params) {

	$scriptPath = join-path (split-path $testScriptPath) 'core/setup.ps1'
	$scriptCommand = '{0} -workDir ''{1}'' {2}' -f $scriptPath,$workDir,$params
	$actualCommand = Get-Content $runSetupPath
	$result = $actualCommand -eq $scriptCommand
	if (-not $result) {
		Write-Debug "`nExpected:`n$scriptCommand`nActual:`n$actualCommand"
	}
	$result
}

function Set-TestDefaults() {
	$global:kubeContexts = 'minikube','EKS','AKS'
	$global:prereqsSatisified = $false
}

Describe 'Generate Setup Command from Default Pass' -Tag 'DefaultPass' {

	BeforeEach {
		Set-TestDefaults
	}

	It '(01) Default responses should generate run-setup.ps1' {
	
		Set-DefaultPass 1 # save w/o prereqs command

		New-Mocks
		. ./guided-setup.ps1

		$runSetupFile = join-path $TestDrive 'run-setup.ps1'
		$expectedParams = "-kubeContextName 'minikube' -namespace 'db' -releaseName 'mariadb' -rootPwd 'my-root-db-password' -replicaCount 0 -binaryLogExpirationSeconds 0 -lowerCaseTableNames 0"
		Test-SetupParameters $PSScriptRoot $runSetupFile $TestDrive $expectedParams | Should -BeTrue
	}
}
