class ChooseContext : Step {

	static [string] hidden $description = @'
Specify the kubectl context where this install will take place so that the 
setup script can fetch configuration data.
'@

	static [string] hidden $noContext = 'I do not have a cluster'

	ChooseContext([ConfigInput] $config) : base(
		[ChooseContext].Name, 
		$config,
		'Kubectl Context',
		[ChooseContext]::description,
		'What''s the kubectl context for this deployment?') {}

	[IQuestion]MakeQuestion([string] $prompt) {

		$contexts = Get-KubectlContexts
		$contexts | ForEach-Object {
			Write-Host $_
		}
		Write-Host
		
		$contextNames = Get-KubectlContexts -nameOnly
		$contextTuples = @()
		$contextTuples += $contextNames | ForEach-Object {
			[tuple]::create($_, "Use the kubectl context named $_ for your deployment")
		}
		$contextTuples += [tuple]::create([ChooseContext]::noContext, "You do not have a cluster and need to create one first")

		return new-object MultipleChoiceQuestion($prompt, $contextTuples, -1)
	}

	[bool]HandleResponse([IQuestion] $question) {

		$mcQuestion = [MultipleChoiceQuestion]$question
		$contextName = $mcQuestion.options[$mcQuestion.choice].item1.replace('&','')
		
		$this.config.kubeContextName = $contextName -eq [ChooseContext]::noContext ? '' : $contextName
		return $true
	}

	[void]Reset(){
		$this.config.kubeContextName = ''
	}
}

class HandleNoContext : Step {

	HandleNoContext([ConfigInput] $config) : base(
		[HandleNoContext].Name, 
		$config,
		'',
		'',
		'') {}

	[bool]Run() {
		Read-Host "Unable to continue because a Kuberenetes cluster is unavailable.`n`nPress Enter to continue"
		return $true
	}

	[bool]CanRun() {
		return -not $this.config.HasContext()
	}
}

class SelectContext: Step {

	SelectContext([ConfigInput] $config) : base(
		[SelectContext].Name, 
		$config,
		'',
		'',
		'') {}

	[bool]Run() {
		Write-HostSection 'Select Kubectl Context' 'Selecting kubectl context...'
		Set-KubectlContext $this.config.kubeContextName

		# retest k8s version prereqs using selected context
		$messages = @()
		$this.config.prereqsSatisified = Test-RequiredKubernetesVersion ([ref]$messages)
		if (-not $this.config.prereqsSatisified) {
			$this.config.missingPrereqs = $messages
			return $true
		}
		
		$question = new-object YesNoQuestion("Continue with selected '$($this.config.kubeContextName)' context?",
			"Yes, continue with this context.",
			"No, select another context.", 0)

		$question.Prompt()
		if (-not $question.hasResponse) {
			return $false
		}
		return $question.choice -eq 0
	}

	[bool]CanRun() {
		return $this.config.HasContext()
	}
}