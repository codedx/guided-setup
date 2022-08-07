<#PSScriptInfo
.VERSION 1.0.0
.GUID 968cc756-ddef-4289-844e-4341ef350f48
.AUTHOR Guided Setup Author
.DESCRIPTION Establishes setup graph and starts guided setup
#>

using module @{ModuleName='Guided-Setup'; RequiredVersion='1.3.0' }

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

Set-PSDebug -Strict

Write-Host 'Loading...' -NoNewline

'./core/steps/config.ps1',
'./core/steps/step.ps1',
'./core/steps/welcome.ps1',
'./core/steps/context.ps1',
'./core/steps/prereq.ps1',
'./core/steps/credential.ps1',
'./core/steps/options.ps1',
'./core/steps/helm.ps1',
'./core/steps/replication.ps1',
'./core/steps/summary.ps1',
'./core/setup/prereqs.ps1' | ForEach-Object {
	Write-Debug "'$PSCommandPath' is including file '$_'"
	$path = join-path $PSScriptRoot $_
	if (-not (Test-Path $path)) {
		Write-Error "Unable to find file script dependency at $path. Please download the entire GitHub repository and rerun the downloaded copy of this script."
	}
	. $path | out-null
}

$config = [ConfigInput]::new()

$graph = New-Object Graph($true)

$s = @{}
[Welcome],
[Prerequisites],[PrequisitesNotMet],
[ChooseContext],[SelectContext],[HandleNoContext],
[WorkDir],
[Namespace],[ReleaseName],
[ReplicaCount],[BinaryLogExpiration],
[RootPwd],[ReplicationPwd],
[MariaDBOptions],[CharacterSet],[Collation],[TableNameCase],
[Finish],[Abort]
| ForEach-Object {
	$s[$_] = new-object -type $_ -args $config
	Add-Step $graph $s[$_]
}

Add-StepTransitions $graph $s[[Welcome]] $s[[Prerequisites]],$s[[PrequisitesNotMet]],$s[[Abort]]
Add-StepTransitions $graph $s[[Welcome]] $s[[Prerequisites]],$s[[ChooseContext]]

Add-StepTransitions $graph $s[[ChooseContext]] $s[[HandleNoContext]],$s[[Abort]]
Add-StepTransitions $graph $s[[ChooseContext]] $s[[SelectContext]],$s[[PrequisitesNotMet]],$s[[Abort]]
Add-StepTransitions $graph $s[[ChooseContext]] $s[[SelectContext]],$s[[WorkDir]],$s[[Namespace]]

Add-StepTransitions $graph $s[[Namespace]] $s[[ReleaseName]],$s[[ReplicaCount]]

Add-StepTransitions $graph $s[[ReplicaCount]] $s[[BinaryLogExpiration]],$s[[RootPwd]]
Add-StepTransitions $graph $s[[ReplicaCount]] $s[[RootPwd]]

Add-StepTransitions $graph $s[[RootPwd]] $s[[ReplicationPwd]],$s[[MariaDBOptions]]
Add-StepTransitions $graph $s[[RootPwd]] $s[[MariaDBOptions]]

Add-StepTransitions $graph $s[[MariaDBOptions]] $s[[CharacterSet]],$s[[Collation]],$s[[TableNameCase]],$s[[Finish]]
Add-StepTransitions $graph $s[[MariaDBOptions]] $s[[Finish]]

if ($DebugPreference -eq 'Continue') {
	# Print graph at https://dreampuf.github.io/GraphvizOnline (select 'dot' Engine and use Format 'png-image-element')
	write-host 'digraph G {'
	$s.keys | ForEach-Object { $node = $s[$_]; ($node.getNeighbors() | ForEach-Object { write-host ('{0} -> {1};' -f $node.name,$_) }) }
	write-host '}'
}

try {
	$vStack = Invoke-GuidedSetup 'MariaDB - Guided Setup' $s[[Welcome]] ($s[[Finish]],$s[[Abort]])

	Write-StepGraph (join-path ($config.workDir ?? './') 'graph.path') $s $vStack
} catch {
	Write-Host "`n`nAn unexpected error occurred: $_`n"
}
