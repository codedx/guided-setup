function New-Password([string] $pwdValue) {
	(new-object net.NetworkCredential("",$pwdValue)).securepassword
}

function Set-NonReplicationWithDefaultOptionsPass([int] $deployType, [int] $saveOption) {
	$global:inputs = new-object collections.queue
	$global:inputs.enqueue($null) # welcome
	$global:inputs.enqueue($deployType) # deployment type
	$global:inputs.enqueue(0) # prereqs
	$global:inputs.enqueue(0) # choose minikube env
	$global:inputs.enqueue(0) # select minikube context
	$global:inputs.enqueue($TestDrive) # workdir
	$global:inputs.enqueue('db') # namespace
	$global:inputs.enqueue('mariadb') # release
	$global:inputs.enqueue(0) # replicas
	$global:inputs.enqueue((New-Password 'my-root-db-password')) # specify root db pwd
	$global:inputs.enqueue((New-Password 'my-root-db-password')) # specify root db pwd confirm
	$global:inputs.enqueue(0) # default options
	$global:inputs.enqueue($saveOption) # next step save option
}

function Set-NonReplicationWithOptionsPass([int] $deployType, [string] $characterSet, [string] $collation, [int] $tableNameCase, [int] $saveOption) {
	$global:inputs = new-object collections.queue
	$global:inputs.enqueue($null) # welcome
	$global:inputs.enqueue($deployType) # deployment type
	$global:inputs.enqueue(0) # prereqs
	$global:inputs.enqueue(0) # choose minikube env
	$global:inputs.enqueue(0) # select minikube context
	$global:inputs.enqueue($TestDrive) # workdir
	$global:inputs.enqueue('db') # namespace
	$global:inputs.enqueue('mariadb') # release
	$global:inputs.enqueue(0) # replicas
	$global:inputs.enqueue((New-Password 'my-root-db-password')) # specify root db pwd
	$global:inputs.enqueue((New-Password 'my-root-db-password')) # specify root db pwd confirm
	$global:inputs.enqueue(1) # custom options
	$global:inputs.enqueue($characterSet) # character set
	$global:inputs.enqueue($collation) # collation
	$global:inputs.enqueue($tableNameCase) # table name case
	$global:inputs.enqueue($saveOption) # next step save option
}

function Set-ReplicationWithOptionsPass([int] $deployType, [int] $replicaCount, [int] $binaryLogExpiration, [string] $characterSet, [string] $collation, [int] $tableNameCase, [int] $saveOption) {
	$global:inputs = new-object collections.queue
	$global:inputs.enqueue($null) # welcome
	$global:inputs.enqueue($deployType) # deployment type
	$global:inputs.enqueue(0) # prereqs
	$global:inputs.enqueue(0) # choose minikube env
	$global:inputs.enqueue(0) # select minikube context
	$global:inputs.enqueue($TestDrive) # workdir
	$global:inputs.enqueue('db') # namespace
	$global:inputs.enqueue('mariadb') # release
	$global:inputs.enqueue($replicaCount) # replicas
	$global:inputs.enqueue($binaryLogExpiration) # binary log file expiration
	$global:inputs.enqueue((New-Password 'my-root-db-password')) # specify root db pwd
	$global:inputs.enqueue((New-Password 'my-root-db-password')) # specify root db pwd confirm
	$global:inputs.enqueue((New-Password 'my-replicator-db-password')) # specify root db pwd
	$global:inputs.enqueue((New-Password 'my-replicator-db-password')) # specify root db pwd confirm
	$global:inputs.enqueue(1) # custom options
	$global:inputs.enqueue($characterSet) # character set
	$global:inputs.enqueue($collation) # collation
	$global:inputs.enqueue($tableNameCase) # table name case
	$global:inputs.enqueue($saveOption) # next step save option
}
