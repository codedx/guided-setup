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

class Finish : Step {

	static [string] hidden $description = @'
You have now specified what's necessary to run the setup script.

At this point, you can launch the script to install components based 
on the configuration data you entered. Alternatively, you can save 
the script command line to a file and run it later.
'@

	Finish([ConfigInput] $config) : base(
		[Finish].Name, 
		$config,
		'Next Step',
		[Finish]::description,
		'What would you like to do next?') {}

	[IQuestion]MakeQuestion([string] $prompt) {

		$options = @(
			[tuple]::create('Save and &Run Script', 'Run the setup script after saving the script command a file'),
			[tuple]::create('&Save Script', 'Save the setup script using password/key script parameters')
		)
		return new-object MultipleChoiceQuestion($prompt, $options, -1)
	}

	[bool]HandleResponse([IQuestion] $question) {
	
		$scriptPath = [io.path]::GetFullPath((join-path $PSScriptRoot '../setup.ps1'))

		$sb = new-object text.stringbuilder($scriptPath)

		'workDir','kubeContextName','namespace','releaseName','rootPwd','replicatorPwd','characterSet','collation' | ForEach-Object {
			$this.AddParameter($sb, $_)
		}
		'replicaCount','binaryLogExpirationSeconds','lowerCaseTableNames' | ForEach-Object {
			$this.AddIntParameter($sb, $_)
		}

		$cmdLine = $sb.ToString()

		$runNow = ([MultipleChoiceQuestion]$question).choice -eq 0

		$this.SaveScripts($cmdLine, (-not $runNow))

		if ($runNow) {
			$this.RunNow($cmdLine)
		}
		return $true
	}

	[void]AddParameter([text.stringbuilder] $sb, [string] $parameterName) {

		$parameterValue = ($this.config | select-object -property $parameterName).$parameterName
		if ($null -ne $parameterValue -and '' -ne $parameterValue) {
			$sb.appendformat(" -{0} '{1}'", $parameterName, ($parameterValue -replace "'","''"))
		}
	}

	[void]AddIntParameter([text.stringbuilder] $sb, [string] $parameterName) {

		$parameterValue = ($this.config | select-object -property $parameterName).$parameterName
		if ($null -ne $parameterValue) {
			$sb.appendformat(" -{0} {1}", $parameterName, $parameterValue)
		}
	}

	[void]SaveScripts([string] $setupCmdLine, [bool] $showRunInstruction) {

		$setupScriptPath = join-path $this.config.workDir 'run-setup.ps1'
		Write-Host "`nWriting $setupScriptPath..."
		$setupCmdLine | Out-File $setupScriptPath

		Write-Host "`nRun the script at any time with this command: pwsh ""$setupScriptPath""`n"
	}

	[bool]RunNow([string] $setupCmdLine) {

		Read-Host "Press Enter to run the script now"
		Write-Host "`nRunning setup command..."

		$cmd = ([convert]::ToBase64String([text.encoding]::unicode.getbytes($setupCmdLine)))
		$process = Start-Process pwsh '-e',$cmd -Wait -PassThru
		if ($process.ExitCode -ne 0) {
			return $false
		}
		return $true
	}
}