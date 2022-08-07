class ConfigInput {

	[bool]   $prereqsSatisified
	[string] $missingPrereqs

	[string] $workDir

	[string] $kubeContextName

	[string] $namespace
	[string] $releaseName

	[int] $replicaCount
	[int] $binaryLogExpirationSeconds

	[string] $rootPwd
	[string] $replicatorPwd

	[bool]   $configureOptions
	[string] $characterSet
	[string] $collation
	[int]    $lowerCaseTableNames

	[bool]HasContext() {
		return $this.kubeContextName -ne ''
	}

	[bool]IsReplicationEnabled() {
		return $this.replicaCount -gt 0
	}
}