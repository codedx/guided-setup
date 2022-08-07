class Prerequisites : Step {

	static [string] hidden $description = @'
Your system must meet these prerequisites:

	- PowerShell Core (v7+)
	- helm v3.1+ (https://github.com/helm/helm/releases/tag/v3.2.4)
	- kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl/)
'@

	Prerequisites([ConfigInput] $config) : base(
		[Prerequisites].Name, 
		$config,
		'',
		'',
		'') {}

	[bool]Run() {
		Write-HostSection 'Prerequisites' ([Prerequisites]::description)

		Write-Host 'Checking prerequisites...'; ([Step]$this).Delay()

		$prereqMessages = @()
		$this.config.prereqsSatisified = Test-SetupPreqs ([ref]$prereqMessages) -checkKubectlVersion:$false

		if (-not $this.config.prereqsSatisified) {
			$this.config.missingPrereqs = $prereqMessages
			Read-HostEnter "`nPress Enter to view missing prerequisites..."
			return $true
		}
		Write-Host 'Done'
		
		return $this.ShouldProceed()
	}

	[bool]ShouldProceed() {

		$response = Read-HostChoice `
			"`nYour system meets the prerequisites. Do you want to continue?" `
			([tuple]::Create('Yes', 'Yes, continue running setup'),[tuple]::Create([question]::previousStepLabel, 'Go back to the previous step'))
			0

		return $response -eq 0
	}
}

class PrequisitesNotMet : Step {

	static [string] hidden $description = @'
Your system does not meet the prerequisites. Rerun this script after 
updating your system/environment.

'@

	PrequisitesNotMet([ConfigInput] $config) : base(
		[PrequisitesNotMet].Name, 
		$config,
		'',
		'',
		'') {}

	[bool]Run() {
		Write-HostSection 'Prequisites Not Met' ([PrequisitesNotMet]::description)

		Write-Host "The following issues were detected:`n"
		foreach ($prereqMessage in $this.config.missingPrereqs) {
			Write-Host $prereqMessage
		}

		Read-HostEnter "`nPress Enter to abort..."
		return $true
	}

	[bool]CanRun() {
		return -not $this.config.prereqsSatisified
	}
}