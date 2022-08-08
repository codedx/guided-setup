class DeploymentMethod : Step {

	static [string] hidden $description = @'
The Guided Setup will help you specify deployment script parameters 
based on your desired configuration and deployment method.

The deployment script supports the following deployment methods:

- Automated Helm Deployment (default)
- Manual Helm Deployment

Note: Enter '?' for deployment method descriptions.
'@

	DeploymentMethod([ConfigInput] $config) : base(
		[DeploymentMethod].Name, 
		$config,
		'Deployment Method',
		[DeploymentMethod]::description,
		'How would you like to deploy MariaDB?') {}

	[IQuestion] MakeQuestion([string] $prompt) {
		return new-object MultipleChoiceQuestion($prompt, @(
			[tuple]::create('&Automated Helm', 'Deployment script will automate running helm with required resources'),
			[tuple]::create('&Manual Helm Deployment', 'Deployment script will generate the required resource and values files, and the helm command to run manually')), 0)
	}

	[bool]HandleResponse([IQuestion] $question) {
		$this.config.resourceFilesOnly = ([MultipleChoiceQuestion]$question).choice -eq 1
		return $true
	}

	[void]Reset() {
		$this.config.resourceFilesOnly = $false
	}
}