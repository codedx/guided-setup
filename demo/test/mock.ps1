
function Get-QueuedInput {

	$val = $global:inputs.dequeue()
	if ($null -ne $val) {
		$val
		Write-Debug "'$val' dequeued"
	} else {
		Write-Debug 'null dequeued'
	}
}

function New-Mocks() {

	Mock Read-HostChoice {
		Write-Host $args
		Get-QueuedInput
	}

	Mock -ModuleName Guided-Setup Read-HostChoice {
		Write-Host $args
		Get-QueuedInput
	}

	Mock Read-Host {
		Write-Host $args
		Get-QueuedInput
	}

	Mock -ModuleName Guided-Setup Read-Host {
		Write-Host $args
		Get-QueuedInput
	}

	Mock Get-KubectlContexts {
		$global:kubeContexts
	}

	Mock Set-KubectlContext {
		Write-Host 'Selecting context...'
	}

	Mock Test-SetupPreqs {
		-not $global:prereqsSatisified
	}

	Mock Test-SetupKubernetesVersion {
		-not $global:prereqsSatisified
	}

	Mock Write-StepGraph {
	}
}
