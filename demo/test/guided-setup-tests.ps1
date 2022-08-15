using module @{ModuleName='guided-setup'; RequiredVersion='1.6.0' }

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

Describe 'Generate Setup Command w/o Replication And Default Options' -Tag 'NoReplicationDefaultOptions' {

	BeforeEach {
		Set-TestDefaults
	}

	It '(01) Non-replication with default options should generate invoke-helm setup command' {
	
		Set-NonReplicationWithDefaultOptionsPass 0 1

		New-Mocks
		. ./guided-setup.ps1

		$runSetupFile = join-path $TestDrive 'run-setup.ps1'
		$expectedParams = "-kubeContextName 'minikube' -namespace 'db' -releaseName 'mariadb' -rootPwd 'my-root-db-password' -replicaCount 0 -binaryLogExpirationSeconds 0 -lowerCaseTableNames 0"
		Test-SetupParameters $PSScriptRoot $runSetupFile $TestDrive $expectedParams | Should -BeTrue
	}

	It '(02) Non-replication with default options should generate create-resource-files setup command' {
	
		Set-NonReplicationWithDefaultOptionsPass 1 1

		New-Mocks
		. ./guided-setup.ps1

		$runSetupFile = join-path $TestDrive 'run-setup.ps1'
		$expectedParams = "-kubeContextName 'minikube' -namespace 'db' -releaseName 'mariadb' -rootPwd 'my-root-db-password' -replicaCount 0 -binaryLogExpirationSeconds 0 -lowerCaseTableNames 0 -resourceFilesOnly"
		Test-SetupParameters $PSScriptRoot $runSetupFile $TestDrive $expectedParams | Should -BeTrue
	}
}

Describe 'Generate Setup Command w/o Replication And MariaDB Options' -Tag 'NoReplicationWithOptions' {

	BeforeEach {
		Set-TestDefaults
	}

	It '(03) Non-replication with options should generate invoke-helm setup command' {
	
		Set-NonReplicationWithOptionsPass 0 'utf8mb4' 'utf8mb4_general_ci' 1 1

		New-Mocks
		. ./guided-setup.ps1

		$runSetupFile = join-path $TestDrive 'run-setup.ps1'
		$expectedParams = "-kubeContextName 'minikube' -namespace 'db' -releaseName 'mariadb' -rootPwd 'my-root-db-password' -characterSet 'utf8mb4' -collation 'utf8mb4_general_ci' -replicaCount 0 -binaryLogExpirationSeconds 0 -lowerCaseTableNames 1"
		Test-SetupParameters $PSScriptRoot $runSetupFile $TestDrive $expectedParams | Should -BeTrue
	}

	It '(04) Non-replication with options should generate create-resource-files setup command' {
	
		Set-NonReplicationWithOptionsPass 1 'utf8mb4' 'utf8mb4_general_ci' 1 1

		New-Mocks
		. ./guided-setup.ps1

		$runSetupFile = join-path $TestDrive 'run-setup.ps1'
		$expectedParams = "-kubeContextName 'minikube' -namespace 'db' -releaseName 'mariadb' -rootPwd 'my-root-db-password' -characterSet 'utf8mb4' -collation 'utf8mb4_general_ci' -replicaCount 0 -binaryLogExpirationSeconds 0 -lowerCaseTableNames 1 -resourceFilesOnly"
		Test-SetupParameters $PSScriptRoot $runSetupFile $TestDrive $expectedParams | Should -BeTrue
	}
}

Describe 'Generate Setup Command w/ Replication And MariaDB Options' -Tag 'WithReplicationWithOptions' {

	BeforeEach {
		Set-TestDefaults
	}

	It '(05) Non-replication with options should generate invoke-helm setup command' {
	
		$binaryLogExpirationDays = 45
		Set-ReplicationWithOptionsPass 0 1 $binaryLogExpirationDays 'utf8mb4' 'utf8mb4_general_ci' 1 1

		New-Mocks
		. ./guided-setup.ps1

		$runSetupFile = join-path $TestDrive 'run-setup.ps1'
		$binaryLogExpirationSeconds = 60 * 60 * 24 * $binaryLogExpirationDays
		$expectedParams = "-kubeContextName 'minikube' -namespace 'db' -releaseName 'mariadb' -rootPwd 'my-root-db-password' -replicatorPwd 'my-replicator-db-password' -characterSet 'utf8mb4' -collation 'utf8mb4_general_ci' -replicaCount 1 -binaryLogExpirationSeconds $binaryLogExpirationSeconds -lowerCaseTableNames 1"
		Test-SetupParameters $PSScriptRoot $runSetupFile $TestDrive $expectedParams | Should -BeTrue
	}

	It '(06) Non-replication with options should generate create-resource-files setup command' {
	
		$binaryLogExpirationDays = 45
		Set-ReplicationWithOptionsPass 1 1 $binaryLogExpirationDays 'utf8mb4' 'utf8mb4_general_ci' 1 1

		New-Mocks
		. ./guided-setup.ps1

		$runSetupFile = join-path $TestDrive 'run-setup.ps1'
		$binaryLogExpirationSeconds = 60 * 60 * 24 * $binaryLogExpirationDays
		$expectedParams = "-kubeContextName 'minikube' -namespace 'db' -releaseName 'mariadb' -rootPwd 'my-root-db-password' -replicatorPwd 'my-replicator-db-password' -characterSet 'utf8mb4' -collation 'utf8mb4_general_ci' -replicaCount 1 -binaryLogExpirationSeconds $binaryLogExpirationSeconds -lowerCaseTableNames 1 -resourceFilesOnly"
		Test-SetupParameters $PSScriptRoot $runSetupFile $TestDrive $expectedParams | Should -BeTrue
	}
}
