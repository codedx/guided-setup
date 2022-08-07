<#PSScriptInfo
.VERSION 1.0.0
.GUID 8e45b2e3-5f13-41a4-8c95-e880beb02973
.AUTHOR Guided Setup Author
.DESCRIPTION Starts a guided setup after conditionally helping with module installation.
#>

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

Set-PSDebug -Strict

. $PSScriptRoot/.install-guided-setup-module.ps1
. $PSScriptRoot/.guided-setup.ps1
