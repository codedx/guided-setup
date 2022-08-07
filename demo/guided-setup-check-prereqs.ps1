<#PSScriptInfo
.VERSION 1.0.0
.GUID 9fda1a9d-55e5-4ffc-9c71-bbae7a823853
.AUTHOR Guided Setup Author
.DESCRIPTION Tests prerequisites for guided setup
#>

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

Set-PSDebug -Strict

'./.install-guided-setup-module.ps1','./core/setup/prereqs.ps1' | ForEach-Object {
	Write-Debug "'$PSCommandPath' is including file '$_'"
	$path = join-path $PSScriptRoot $_
	if (-not (Test-Path $path)) {
		Write-Error "Unable to find file script dependency at $path. Please download the entire GitHub repository and rerun the downloaded copy of this script."
	}
	. $path | out-null
}

$prereqMessages = @()
if (-not (Test-SetupPreqs ([ref]$prereqMessages) -checkKubectlVersion)) {
	Write-Host "`nYour system does not meet the Guided Setup prerequisites:`n"
	$prereqMessages | ForEach-Object {
		Write-Host "* $_`n"
	}
	exit 1
}
Write-Host "`n`nYour system meets the Guided Setup prerequisites.`n"
