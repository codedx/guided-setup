function New-MariaDBValuesFile([string] $dbExistingSecretName,
	[string] $dbExistingConfigMapName,
	[string] $primaryName,
	[string] $replicaName,
	[int]    $replicaCount,
	[string] $valuesFile) {

	$architecture = 'standalone'
	$usingReplication = $replicaCount -gt 0
	if ($usingReplication) {
		$architecture = 'replication'
	}
		
	$values = @'
auth:
  existingSecret: {0}

architecture: {1}

primary:
  existingConfigmap: {2}
  name: {3}

secondary:
  existingConfigmap: {2}
  name: {4}
  replicaCount: {5}
'@

	$values -f `
		$dbExistingSecretName,    #0
		$architecture,            #1
		$dbExistingConfigMapName, #2
		$primaryName,             #3
		$replicaName,             #4
		$replicaCount `           #5
			| out-file $valuesFile -Encoding ascii -Force
}