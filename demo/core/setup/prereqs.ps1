function Test-SetupPreqs([ref] $messages, [string] $context, [switch] $checkKubectlVersion) {

	$messages.Value = @()
	$isCore = Test-IsCore
	if (-not $isCore) {
		$messages.Value += 'Unable to continue because you must run this script with PowerShell Core (pwsh)'
	}
	
	if ($isCore -and -not (Test-MinPsMajorVersion 7)) {
		$messages.Value += 'Unable to continue because you must run this script with PowerShell Core 7 or later'
	}
	
	$apps = 'helm','kubectl'

	$appStatus = @{}
	$apps | foreach-object {
		$found = $null -ne (Get-AppCommandPath $_)
		$appStatus[$_] = $found

		if (-not $found) {
			$messages.Value += "Unable to continue because $_ cannot be found. Is $_ installed and included in your PATH?"
		}
		if ($found -and $_ -eq 'helm') {
			$helmVersion = Get-HelmVersionMajorMinor
			if ($null -eq $helmVersion) {
				$messages.Value += 'Unable to continue because helm version was not detected.'
			}
			
			$minimumHelmVersion = 3.1 # required for helm lookup function
			if ($helmVersion -lt $minimumHelmVersion) {
				$messages.Value += "Unable to continue with helm version $helmVersion, version $minimumHelmVersion or later is required"
			}
		}
	}

	$canUseKubectl = $appStatus['kubectl']
	if ($canUseKubectl -and $checkKubectlVersion) {

		if ($context -eq '') {
			$context = Get-KubectlContext
		}
		Set-KubectlContext $context

		$k8sMessages = @()
		if (-not (Test-RequiredKubernetesVersion ([ref]$k8sMessages))) {
			$messages.Value += $k8sMessages
			$messages.Value += "Note: The prerequisite check used kubectl context '$context'"
		}
	}

	$messages.Value.count -eq 0
}

function Test-RequiredKubernetesVersion ([ref]$k8sMessages) {

	$k8sRequiredMajorVersion = 1
	$k8sMinimumMinorVersion = 19
	$k8sMaximumMinorVersion = 24
	Test-SetupKubernetesVersion $k8sMessages $k8sRequiredMajorVersion $k8sMinimumMinorVersion $k8sMaximumMinorVersion
}