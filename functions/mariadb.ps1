<#PSScriptInfo
.VERSION 1.1.0
.GUID 0bccb44c-14f1-44c0-b41b-3fa02f5bb412
.AUTHOR Black Duck
.COPYRIGHT Copyright 2024 Black Duck Software, Inc. All rights reserved.
.DESCRIPTION Includes MariaDB-related helpers
#>

function Copy-DBBackupFiles([string] $namespace, 
	[string] $backupFiles,
	[string] $podName,
	[string] $containerName,
	[string] $destinationPath) {

	kubectl -n $namespace exec -c $containerName $podName -- rm -Rf $destinationPath
	kubectl -n $namespace exec -c $containerName $podName -- mkdir -p $destinationPath
	if (0 -ne $LASTEXITCODE) {
		Write-Error "Unable to create directory to store backup files, kubectl exited with exit code $LASTEXITCODE."
	}

	$backupFilesParent = Split-Path $backupFiles -Parent
	Push-Location $backupFilesParent

	$sourcePath = Split-Path $backupFiles -Leaf
	kubectl -n $namespace cp   -c $containerName $sourcePath $podName`:$destinationPath
	if (0 -ne $LASTEXITCODE) {
		Write-Error "Unable to copy backup files to pod, kubectl exited with exit code $LASTEXITCODE."
	}
	Pop-Location
}

function Stop-SlaveDB([string] $namespace, 
	[string] $podName,
	[string] $containerName,
	[string] $rootPwd) {

	kubectl -n $namespace exec -c $containerName $podName -- mysqladmin -uroot --password=$rootPwd stop-slave
	if (0 -ne $LASTEXITCODE) {
		Write-Error "Unable to stop DB slave, kubectl exited with exit code $LASTEXITCODE."
	}
}

function Get-MasterFilePosAfterReset([string] $namespace,
	[string] $containerName,
	[string] $podName,
	[string] $rootPwd) {

	$cmd = 'RESET MASTER;FLUSH TABLES WITH READ LOCK;SHOW MASTER STATUS \G;UNLOCK TABLES;'
	$output = kubectl -n $namespace exec -c $containerName $podName -- mysql -uroot --password=$rootPwd -e $cmd
	if (0 -ne $LASTEXITCODE) {
	  throw "Unable to get file position from master, kubectl exited with exit code $LASTEXITCODE."
	}

	$filePos = @{}
	$fileMatch = $output | select-string -pattern 'File:\s(?<file>.+)$'
	$filePos.file = $fileMatch.matches.Groups[1].value

	$positionMatch = $output | select-string -pattern 'Position:\s(?<file>\d+)$'
	$filePos.position = $positionMatch.matches.Groups[1].value

	$filePos
}

function Start-SlaveDB([string] $namespace, 
	[string] $podName,
	[string] $containerName,
	[string] $replUsername,
	[string] $replPwd,
	[string] $rootPwd,
	[string] $mariaDbServiceName,
	$filePos) {

	# Assume `STOP SLAVE` (or Stop-SlaveDB) was run
	$cmd = "RESET SLAVE; CHANGE MASTER TO MASTER_LOG_FILE='$($filePos.file)',MASTER_LOG_POS=$($filePos.position),MASTER_HOST='$mariaDbServiceName',MASTER_USER='$replUsername',MASTER_PASSWORD='$replPwd'; START SLAVE; SHOW SLAVE STATUS \G;"

	kubectl -n $namespace exec -c $containerName $podName -- mysql -uroot --password=$rootPwd -e $cmd
	if (0 -ne $LASTEXITCODE) {
		Write-Error "Unable to start DB slave, kubectl exited with exit code $LASTEXITCODE."
	}
}

function Get-DatabaseUrl([string] $databaseHost, [int] $databasePort,
	[string] $databaseName,
	[string] $databaseCertPath,
	[switch] $databaseSkipTls) {

	$url = "jdbc:mysql://$databaseHost"
	if ($databasePort -ne 3306) {
		$url = "$url`:$databasePort"
	}

	$url = "$url/$databaseName"

	if (-not $databaseSkipTls) {

		if ($databaseCertPath -eq '' -or -not (Test-Path $databaseCertPath -PathType Leaf)) {
			throw "Using a One-Way SSL/TLS configuration requires a server certificate"
		}
		$url = "$url`?useSSL=true&requireSSL=true"
	}
	$url
}

function Remove-Database([string] $namespace, 
	[string] $podName,
	[string] $containerName,
	[string] $rootPwd,
	[string] $databaseName) {

	$cmd = "DROP DATABASE IF EXISTS $databaseName"

	kubectl -n $namespace exec -c $containerName $podName -- mysql -uroot --password=$rootPwd -e $cmd
	if (0 -ne $LASTEXITCODE) {
		Write-Error "Unable to drop database, kubectl exited with exit code $LASTEXITCODE."
	}
}

function New-Database([string] $namespace, 
	[string] $podName,
	[string] $containerName,
	[string] $rootPwd,
	[string] $databaseName,
	[string] $databaseDump,
	[switch] $skipDropDatabase) {

	if (-not $skipDropDatabase) {
		Remove-Database $namespace $podName $containerName $rootPwd $databaseName 
	}

	$cmd = "CREATE DATABASE $databaseName"

	kubectl -n $namespace exec -c $containerName $podName -- mysql -uroot --password=$rootPwd -e $cmd
	if (0 -ne $LASTEXITCODE) {
		Write-Error "Unable to create database, kubectl exited with exit code $LASTEXITCODE."
	}

	if (-not (Test-Path $databaseDump -PathType Leaf)) {
		Write-Error "Unable to find database dump file at $databaseDump."
	}

	$importPath = '/tmp/import.sql'
	Copy-K8sItem $namespace $databaseDump $podName $containerName $importPath

	kubectl -n $namespace exec -c $containerName $podName -- bash -c "mysql -uroot --password=""$rootPwd"" $databaseName < $importPath"
	if (0 -ne $LASTEXITCODE) {
		Write-Error "Unable to import database dump, kubectl exited with exit code $LASTEXITCODE."
	}
}

function Test-Database([string] $namespace, 
	[string] $podName,
	[string] $containerName,
	[string] $rootPwd) {

	kubectl -n $namespace exec -c $containerName $podName -- bash -c "mysqladmin -uroot --password=""$rootPwd"" status" | out-null
	0 -eq $LASTEXITCODE
}
