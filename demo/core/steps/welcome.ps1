class Welcome : Step {

	Welcome([ConfigInput] $config) : base(
		[Welcome].Name, 
		$config, 
		'', 
		'', 
		'') {}

	[bool]Run() {
        Write-Host '#     #                        ######  ######  '
        Write-Host '##   ##   ##   #####  #   ##   #     # #     # '
        Write-Host '# # # #  #  #  #    # #  #  #  #     # #     # '
        Write-Host '#  #  # #    # #    # # #    # #     # ######  '
        Write-Host '#     # ###### #####  # ###### #     # #     # '
        Write-Host '#     # #    # #   #  # #    # #     # #     # '
        Write-Host "#     # #    # #    # # #    # ######  ######`n`n"
        Read-HostEnter
		return $true
	}
}

class Abort : Step {

	Abort([ConfigInput] $config) : base(
		[Abort].Name, 
		$config,
		'',
		'',
		'') {}

	[bool]Run() {
		Write-Host 'Setup aborted'
		return $true
	}
}

class WorkDir : Step {

	static [string] hidden $description = @'
Specify a directory to store files generated during the setup process. Files 
in your work directory may contain data that should be kept private.
'@

	[string] $homeDirectory = $HOME

	WorkDir([ConfigInput] $config) : base(
		[WorkDir].Name, 
		$config,
		'Work Directory',
		[WorkDir]::description,
		"Enter a directory or press Enter to accept the default ($HOME/.k8s-mariadb)") {}

	[IQuestion] MakeQuestion([string] $prompt) {
		$question = new-object Question($prompt)
		$question.allowEmptyResponse = $true
		return $question
	}

	[bool]HandleResponse([IQuestion] $question) {
		$q = [Question]$question
		$this.config.workDir = $q.isResponseEmpty ? "$($this.homeDirectory)/.k8s-mariadb" : $q.response

		if (-not (Test-Path $this.config.workDir -Type Container)) {
			try {
				New-Item -ItemType Directory $this.config.workDir | out-null
			} catch {
				Write-Host "Cannot create directory $($this.config.workDir): " $_
				$this.config.workDir = ''
				return $false
			}
		}

		return $true
	}
}