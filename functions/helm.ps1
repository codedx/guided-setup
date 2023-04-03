<#PSScriptInfo
.VERSION 1.3.0
.GUID 04273f72-e001-415b-add0-e5e95e378355
.AUTHOR Code Dx
.DESCRIPTION Includes Helm-related helpers
#>

function Get-HelmReleaseHistory([string] $namespace, [string] $releaseName) {

	$history = helm -n $namespace history $releaseName --max 1 -o json
	if ($null -eq $history) {
		return $null
	}

	convertfrom-json $history
}

function Get-HelmReleaseAppVersion([string] $namespace, [string] $releaseName) {

	$history = Get-HelmReleaseHistory $namespace $releaseName
	if ($null -eq $history) {
		return $null
	}

	new-object Management.Automation.SemanticVersion($history.app_version)
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

function Invoke-HelmCommand([string] $message, 
	[int]      $waitSeconds, 
	[string]   $namespace, 
	[string]   $releaseName, 
	[string]   $timeout = '5m0s',
	[string]   $chartReference, 
	[string]   $valuesFile,  
	[string[]] $extraValuesPaths, 
	[string]   $version, 
	[switch]   $reuseValues,
	[switch]   $dryRun,
	[switch]   $skipCRDs) {

	if (test-path $chartReference -pathtype container) {
		Write-Verbose 'Running helm dependency update...'
		helm dependency update $chartReference | Out-Null
		if ($LASTEXITCODE -ne 0) {
			throw "Unable to run dependency update, helm exited with code $LASTEXITCODE."
		}
	}

	if (-not $dryRun) {
		if (Test-Namespace $namespace) {
			Wait-AllRunningPods "Pre-Helm Install: $message" $waitSeconds $namespace
		} else {
			Write-Verbose "Skipping pre-helm install check because namespace '$namespace' does not exist or insufficient privileges affected the namespace test."
		}
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
	
		Write-Verbose "Running Helm Upgrade: $message (timeout $timeout)..."

		$dryRunParam = $dryRun ? '--dry-run' : ''
		$debugParam = $dryRun ? '--debug' : ''

		$valuesParam = '--reset-values' # merge $values with the latest, default chart values
		if ($reuseValues) {
			$valuesParam = '--reuse-values' # merge $values used with the last upgrade
		}

		$crdAction = $skipCRDs ? '--skip-crds' : ''
		$helmOutput = helm upgrade --namespace $namespace --install --create-namespace $valuesParam $releaseName --timeout $timeout @values $chartReference @versionParam $crdAction $dryRunParam $debugParam
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
