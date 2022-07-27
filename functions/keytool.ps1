<#PSScriptInfo
.VERSION 1.0.0
.GUID d73b9c33-1ca5-40c2-bbce-ff18efd062ab
.AUTHOR Code Dx
.DESCRIPTION Includes keytool-related helpers
#>

function Get-KeystorePasswordEscaped([string] $keystorePwd) {
	$keystorePwd.Replace('"','\"')
}

function Test-KeystorePassword([string] $keystorePath, [string] $keystorePwd) {

	$Local:ErrorActionPreference = 'SilentlyContinue'
	$keystorePwd = Get-KeystorePasswordEscaped $keystorePwd
	keytool -list -keystore $keystorePath -storepass $keystorePwd *>&1 | out-null
	$LASTEXITCODE -eq 0
}

function Set-KeystorePassword([string] $keystorePath, [string] $keystorePwd, [string] $newKeystorePwd) {

	if (-not (Test-KeystorePassword $keystorePath $keystorePwd)) {
		if (Test-KeystorePassword $keystorePath $newKeystorePwd) {
			return # password is already set
		}
		throw "Unable to change keystore password because the specified old keystore password is invalid for file '$keystorePath'"
	}

	keytool -storepasswd -keystore $keystorePath -storepass (Get-KeystorePasswordEscaped $keystorePwd) -new (Get-KeystorePasswordEscaped $newKeystorePwd)
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to change keystore password, keytool exited with code $LASTEXITCODE."
	}
}

function Remove-KeystoreAlias([string] $keystorePath, [string] $keystorePwd, [string] $aliasName) {

	keytool -delete -alias $aliasName -keystore $keystorePath -storepass (Get-KeystorePasswordEscaped $keystorePwd)
}

function Add-KeystoreAlias([string] $keystorePath, [string] $keystorePwd, [string] $aliasName, [string] $certFile) {

	keytool -import -trustcacerts -keystore $keystorePath -file $certFile -alias $aliasName -noprompt -storepass (Get-KeystorePasswordEscaped $keystorePwd)
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to import certificate '$certFile' into keystore, keytool exited with code $LASTEXITCODE."
	}
}

function Get-TrustedCaCertAlias([string] $certFile) {
	split-path $certFile -leaf
}

function Import-TrustedCaCert([string] $keystorePath, [string] $keystorePwd, [string] $certFile) {

	if (-not (Test-Path $certFile -PathType Leaf)) {
		throw "Unable to import cert file '$certFile' because it does not exist."
	}

	$aliasName = Get-TrustedCaCertAlias $certFile

	Remove-KeystoreAlias $keystorePath $keystorePwd $aliasName
	Add-KeystoreAlias $keystorePath $keystorePwd $aliasName $certFile
}

function Import-TrustedCaCerts([string] $keystorePath, [string] $keystorePwd, [string[]] $certFiles) {

	if ($certFiles.Count -eq 0) {
		return
	}

	$uniqueAliasCount = ($certFiles | ForEach-Object {
		Get-TrustedCaCertAlias $_
	} | Select-Object -Unique).count

	if ($certFiles.Count -ne $uniqueAliasCount) {
		throw "Unable to import cert files because one or more certificates will map to the same alias"
	}

	$certFiles | ForEach-Object {
		Import-TrustedCaCert $keystorePath $keystorePwd $_
	}
}

function Test-Certificate([string] $path) {

	$Local:ErrorActionPreference = 'SilentlyContinue'
	keytool -printcert -file $path *>&1 | out-null
	$LASTEXITCODE -eq 0
}

function Get-KeytoolJavaSettings() {

	$keytoolPath = Get-AppCommandPath 'keytool' | Select-Object -First 1
	if ($null -eq $keytoolPath) {
		return $null
	}

	$javaSettings = $null
	$local:ErrorActionPreference = 'Continue'

	Push-Location (Split-Path $keytoolPath)
	if ((Test-Path java -PathType Leaf) -or (Test-Path java.exe -PathType Leaf)) {
		$javaSettings = ./java -XshowSettings:all -version 2>&1
	}
	Pop-Location

	$javaSettings
}

function Get-KeytoolJavaSpec() {

	$javaSettings = Get-KeytoolJavaSettings
	if ($null -eq $javaSettings) {
		return $null
	}
	if (-not ($javaSettings | select-string  'java.vm.specification.version' | ForEach-Object { $_ -match 'java.vm.specification.version\s=\s(?<version>.+)' })) {
		return $null
	}
	$matches['version']
}
