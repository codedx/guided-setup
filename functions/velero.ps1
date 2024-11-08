<#PSScriptInfo
.VERSION 1.0.0
.GUID d59ec807-d430-4d6a-ae7b-6e0ad9e8f9b5
.AUTHOR Black Duck
.COPYRIGHT Copyright 2024 Black Duck Software, Inc. All rights reserved.
.DESCRIPTION Includes Velero-related helpers.
#>

function Test-VeleroBackupSchedule([string] $namespace, [string] $name) {

	$Local:ErrorActionPreference = 'SilentlyContinue'
	kubectl -n $namespace get "schedule/$name" *>&1 | Out-Null
	$LASTEXITCODE -eq 0
}

function Remove-VeleroBackupSchedule([string] $namespace, [string] $name) {

	kubectl -n $namespace delete schedule $name | out-null
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to delete Velero Schedule named $name, kubectl exited with code $LASTEXITCODE."
	}
}