class Namespace : Step {

	static [string] hidden $description = @'
Specify the Kubernetes namespace where MariaDB components will be installed. 
For example, to install components in a namespace named 'db', enter  
that name here.

Note: Press Enter to use the example namespace.
'@

	static [string] hidden $default = 'db'

	Namespace([ConfigInput] $config) : base(
		[Namespace].Name, 
		$config,
		'Namespace',
		[Namespace]::description,
		"Enter namespace name (e.g., $([Namespace]::default))") {}

	[IQuestion] MakeQuestion([string] $prompt) {
		$question = new-object Question($prompt)
		$question.allowEmptyResponse = $true
		$question.emptyResponseLabel = "Accept default ($([Namespace]::default))"
		$question.validationExpr = '^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$'
		$question.validationHelp = 'The namespace must consist of lowercase alphanumeric characters or ''-'', and must start and end with an alphanumeric character'
		return $question
	}

	[bool]HandleResponse([IQuestion] $question) {
		$this.config.namespace = ([Question]$question).GetResponse([Namespace]::default)
		return $true
	}

	[void]Reset(){
		$this.config.namespace = [Namespace]::default
	}
}

class ReleaseName : Step {

	static [string] hidden $description = @'
Specify the Helm release name for the MariaDB deployment. The name should not 
conflict with another Helm release in the Kubernetes namespace you chose.

If you plan to install multiple copies of the MariaDB Helm chart on a single 
cluster, specify a unique release name for each instance.

Note: Press Enter to use the example release name.
'@

	static [string] hidden $default = 'mariadb'

	ReleaseName([ConfigInput] $config) : base(
		[ReleaseName].Name, 
		$config,
		'Helm Release Name',
		[ReleaseName]::description,
		"Enter Helm release name (e.g., $([ReleaseName]::default))") {}

	[IQuestion] MakeQuestion([string] $prompt) {
		$question = new-object Question($prompt)
		$question.allowEmptyResponse = $true
		$question.emptyResponseLabel = "Accept default ($([ReleaseName]::default))"
		$question.validationExpr = '^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$'
		$question.validationHelp = 'The release name must consist of lowercase alphanumeric characters or ''-'', and must start and end with an alphanumeric character'
		return $question
	}

	[bool]HandleResponse([IQuestion] $question) {
		$this.config.releaseName = ([Question]$question).GetResponse([ReleaseName]::default)
		return $true
	}

	[void]Reset(){
		$this.config.releaseName = [ReleaseName]::default
	}
}