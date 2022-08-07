class RootPwd : Step {

	static [string] hidden $description = @'
Specify the password for the MariaDB root user that the deployment 
will create when provisioning the MariaDB database.
'@

	RootPwd([ConfigInput] $config) : base(
		[RootPwd].Name, 
		$config,
		'Database Root Password',
		[RootPwd]::description,
		'Enter a password for the MariaDB root user') {}

	[IQuestion]MakeQuestion([string] $prompt) {
		$question = new-object ConfirmationQuestion($prompt)
		$question.isSecure = $true
		$question.blacklist = @("'")
		$question.minimumLength = 8
		return $question
	}

	[bool]HandleResponse([IQuestion] $question) {
		$this.config.rootPwd = ([ConfirmationQuestion]$question).response
		return $true
	}

	[void]Reset(){
		$this.config.rootPwd = ''
	}
}

class ReplicationPwd : Step {

	static [string] hidden $description = @'
Specify the password for the MariaDB replication user that the deployment 
will create when provisioning the MariaDB database.
'@

ReplicationPwd([ConfigInput] $config) : base(	
		[ReplicationPwd].Name, 
		$config,
		'Database Replication Password',
		[ReplicationPwd]::description,
		'Enter a password for the MariaDB replicator user') {}

	[IQuestion]MakeQuestion([string] $prompt) {
		$question = new-object ConfirmationQuestion($prompt)
		$question.isSecure = $true
		$question.blacklist = @("'")
		$question.minimumLength = 8
		return $question
	}

	[bool]HandleResponse([IQuestion] $question) {
		$replicatorPwd = ([ConfirmationQuestion]$question).response

		if ($replicatorPwd -eq $this.config.rootPwd) {
			Write-Host "`nSpecify another password to avoid reusing the root password`n"
			return $false
		}
		$this.config.replicatorPwd = $replicatorPwd
		return $true
	}

	[void]Reset(){
		$this.config.replicatorPwd = ''
	}

	[bool]CanRun() {
		return $this.config.IsReplicationEnabled()
	}
}
