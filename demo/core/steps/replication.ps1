class ReplicaCount : Step {

	static [string] hidden $description = @'
Specify the number of replica databases that will use data replication 
to store a copy of the MariaDB primary database.

Note: Enter 0 if you are planning to skip database replication.
'@

	ReplicaCount([ConfigInput] $config) : base(
		[ReplicaCount].Name, 
		$config,
		'Database Replicas',
		[ReplicaCount]::description,
		'Enter the number of database replicas') {}
	
	[IQuestion]MakeQuestion([string] $prompt) {
		return new-object IntegerQuestion($prompt, 0, 5, $false)
	}

	[bool]HandleResponse([IQuestion] $question) {
		$this.config.replicaCount = ([IntegerQuestion]$question).intResponse
		return $true
	}

	[void]Reset(){
		$this.config.replicaCount = 1
	}
}

class BinaryLogExpiration : Step {

	static [string] hidden $description = @'
Specify the number of days to protect binary log files from purging.

Choose a value greater than the maximum lag between primary and replica.

Enter 0 to disable automatic binary log file purging. Monitor disk 
usage and run PURGE BINARY LOGS as required to avoid unnecessary 
log file storage.
'@

	BinaryLogExpiration([ConfigInput] $config) : base(
		[BinaryLogExpiration].Name, 
		$config,
		'Binary Log Expiration',
		[BinaryLogExpiration]::description,
		'Enter the number of days to preserve binary logs') {}
	
	[IQuestion]MakeQuestion([string] $prompt) {
		return new-object IntegerQuestion($prompt, 0, 45, $false)
	}

	[bool]HandleResponse([IQuestion] $question) {
		$days = ([IntegerQuestion]$question).intResponse
		$this.config.binaryLogExpirationSeconds = $days * 24 * 60 * 60
		return $true
	}

	[void]Reset(){
		$this.config.binaryLogExpirationSeconds = 0
	}

	[bool]CanRun() {
		return $this.config.IsReplicationEnabled()
	}
}
