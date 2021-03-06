<#PSScriptInfo
.VERSION 1.0.0
.GUID 04273f72-e001-415b-add0-e5e95e378355
.AUTHOR Code Dx
.DESCRIPTION Includes Helm-related helpers
#>

function Get-HelmReleaseAppVersion([string] $namespace, [string] $releaseName) {

	$history = helm -n $namespace history $releaseName --max 1 -o json
	if ($null -eq $history) {
		return $null
	}

	$historyJson = convertfrom-json $history
	new-object Management.Automation.SemanticVersion($historyJson.app_version)
}

function Add-HelmRepo([string] $name, [string] $url) {

	helm repo add $name $url
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to add helm repository, helm exited with code $LASTEXITCODE."
	}

	helm repo update
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to run helm repo update, helm exited with code $LASTEXITCODE."
	}
}

function Test-HelmRelease([string] $namespace, [string] $releaseName) {

	$Local:ErrorActionPreference = 'SilentlyContinue'
	helm -n $namespace status $releaseName *>&1 | Out-Null
	$LASTEXITCODE -eq 0
}

function Get-HelmValues([string] $namespace, [string] $releaseName) {

	$values = helm -n $namespace get values $releaseName -o json
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to get release values, helm exited with code $LASTEXITCODE."
	}
	ConvertFrom-Json $values
}

function Invoke-HelmSingleDeployment([string] $message, 
	[int]      $waitSeconds, 
	[string]   $namespace, 
	[string]   $releaseName, 
	[string]   $chartReference, 
	[string]   $valuesFile, 
	[string]   $deploymentName, 
	[int]      $totalReplicas, 
	[string[]] $extraValuesPaths, 
	[string]   $version, 
	[switch]   $reuseValues,
	[switch]   $dryRun,
	[switch]   $skipCRDs) {

	if (-not $dryRun) {
		if (-not (Test-Namespace $namespace)) {
			New-Namespace  $namespace
		}
	}

	if (test-path $chartReference -pathtype container) {
		Write-Verbose 'Running helm dependency update...'
		helm dependency update $chartReference | Out-Null
		if ($LASTEXITCODE -ne 0) {
			throw "Unable to run dependency update, helm exited with code $LASTEXITCODE."
		}
	}

	if (-not $dryRun) {
		Wait-AllRunningPods "Pre-Helm Install: $message" $waitSeconds $namespace
	}
	
	# NOTE: Latter values files take precedence over former ones
	$valuesPaths = $extraValuesPaths
	if ($valuesFile -ne '') {
		$valuesPaths = @($valuesFile) + $extraValuesPaths
	}

	$values = @()
	$tmpPaths = @()
	$helmOutput = ''
	try {
		$valuesPaths | ForEach-Object {
			$values = $values + "--values"
			$valuesFilePath = Set-KubectlFromFilePath $_ ([ref]$tmpPaths)
			$values = $values + ('"{0}"' -f $valuesFilePath)
		}

		$versionParam = @()
		if ('' -ne $version) {
			$versionParam = $versionParam + "--version"
			$versionParam = $versionParam + "$version"
		}
		
		Write-Verbose "Running Helm Upgrade: $message..."

		$dryRunParam = $dryRun ? '--dry-run' : ''
		$debugParam = $dryRun ? '--debug' : ''

		$valuesParam = '--reset-values' # merge $values with the latest, default chart values
		if ($reuseValues) {
			$valuesParam = '--reuse-values' # merge $values used with the last upgrade
		}

		$crdAction = $skipCRDs ? '--skip-crds' : ''
		$helmOutput = helm upgrade --namespace $namespace --install $valuesParam $releaseName @($values) $chartReference @($versionParam) $crdAction $dryRunParam $debugParam
		if ($LASTEXITCODE -ne 0) {
			throw "Unable to run helm upgrade/install, helm exited with code $LASTEXITCODE."
		}

		$helmOutput = $helmOutput -join [Environment]::NewLine
		Write-Verbose "Helm output: $helmOutput"

		if ($dryRun) {

			$manifestLabel = 'MANIFEST:'
			$manifestIndex = $helmOutput.indexof($manifestLabel) + $manifestLabel.length

			$notesIndex = $helmOutput.indexof('NOTES:')
			if ($notesIndex -eq -1) {
				$notesIndex = $helmOutput.length - 1
			}

			# Usable content is between 'MANIFEST:' and 'NOTES:'
			$helmOutput = $helmOutput.substring($manifestIndex, $notesIndex - $manifestIndex)
		}
	} finally {
		$tmpPaths | ForEach-Object { Write-Verbose "Removing temporary file '$_'"; Remove-Item $_ -Force }
	}

	if (-not $dryRun) {
		Wait-Deployment "Helm Upgrade/Install: $message" $waitSeconds $namespace $deploymentName $totalReplicas
	}

	return $helmOutput
}

function Get-HelmVersionMajorMinor() {

	$versionMatch = helm version -c | select-string 'Version:"v(?<version>\d+\.\d+)'
	if ($null -eq $versionMatch -or -not $versionMatch.Matches.Success) {
		return $null
	}
	[double]$versionMatch.Matches.Groups[1].Value
}

function Get-HelmChartFullname([string] $releaseName, [string] $chartName) {

	$fullname = $releaseName
	if ($releaseName -cne $chartName) {
		$fullname = "$releaseName-$chartName"
	}
	Get-CommonName $fullname
}

function Get-CommonName([string] $name) {

	# note: matches chart "sanitize" helper
	if ($name.length -gt 63) {
		$name = $name.Substring(0, 63)
	}
	$name.TrimEnd('-')
}
