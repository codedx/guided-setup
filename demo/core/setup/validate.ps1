function Test-SetupParams([ref] $messages, 
	[string[]] $stringParameterNames,
	[string[]] $positiveIntParameterNames,
	[string]   $rootPwd,
	[string]   $replicatorPwd,
	[int]      $replicaCount,
	[int]      $lowerCaseTableNames,
	[string]   $workDirectory,
	[string[]] $extraValuesFiles) {

	$messages.Value = @()

	$useReplication = $replicaCount -gt 0

	### Validate string parameters
	$emptyStringExceptionList = @()
	if (-not $useReplication) {
		$emptyStringExceptionList += ('replicatorPwd','replicaName')
	}
	$stringParameterNames | ForEach-Object {
		$var = Get-Variable -Name $_
		$onExceptionList = $emptyStringExceptionList -contains $_
		if (-not $onExceptionList -and [string]::IsNullOrWhiteSpace($var.Value)) {
			$messages.Value += "Invalid string value for parameter; please specify a value for -$($var.Name)."
		}
	}

	### Validate positive int parameters
	$positiveIntParameterNames | ForEach-Object {
		$var = (Get-Variable -Name $_)
		if ($var.Value -lt 0) {
			$messages.Value += "Invalid int value for parameter; please specify a number greater than 0 for -$($var.Name)."
		}
	}

	### Validate choice parameters
	$validLowerCaseTableNames = 0,1,2
	if ($validLowerCaseTableNames -notcontains $lowerCaseTableNames) {
		$messages.Value += "Invalid choice for parameter; please specify a valid value ($validLowerCaseTableNames) for -lowerCaseTableNames."
	}

	### Validate work directory
	if (-not (Test-Path $workDirectory -PathType Container)) {
		$messages.Value += "Invalid directory ($workDir) for parameter -workDir; please specify an existing directory."
	}

	### Validate extra values files
	$extraValuesFiles | ForEach-Object {
		if (-not (Test-Path $_ -PathType Any)) {
			$messages.Value += "Invalid values file ($_); please specify existing values files."
		}
	}

	$passwordsToCheck = @([tuple]::create('rootPwd', $rootPwd))
	if ($useReplication) {
		$passwordsToCheck += [tuple]::create('replicatorPwd', $replicatorPwd)
	}

	$passwordsToCheck | ForEach-Object {
		$passwordMessages = @()
		if (-not (Test-MariaDBPassword ([ref]$passwordMessages) $_.item1 $_.item2 )) {
			$passwordMessages | ForEach-Object {
				$messages.Value += $_
			}
		}
	}

	$messages.Value.count -eq 0
}

function Test-MariaDBPassword([ref] $messages, [string] $paramName, [string] $paramValue) {

	$messages.Value = @()

	$paramValueLength = $paramValue.Length
	if ($paramValueLength -lt 8 -or $paramValueLength -gt 32) {
		$messages.Value += "Value for parameter -$paramName must be between 8 and 32 characters"
	}
	if ($paramValue.Contains("-")) {
		$messages.Value += "Value for parameter -$paramName must not contain a single quote character"
	}

	$messages.Value.count -eq 0
}
