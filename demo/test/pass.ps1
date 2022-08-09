function New-Password([string] $pwdValue) {
	(new-object net.NetworkCredential("",$pwdValue)).securepassword
}

function Set-DefaultPass([int] $saveOption) {
	$global:inputs = new-object collections.queue
	$global:inputs.enqueue($null) # welcome
	$global:inputs.enqueue(0) # automate helm
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