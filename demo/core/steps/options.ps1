class MariaDBOptions : Step {

	static [string] hidden $description = @'
Specify whether you want to customize MariaDB options.
'@

	static [string] $defaultCharacterSet = 'utf8'
	static [string] $defaultCollation = 'utf8_general_ci'
	static [int]    $defaultLowerCaseTableNames = 0

	MariaDBOptions([ConfigInput] $config) : base(
		[MariaDBOptions].Name, 
		$config,
		'MariaDB Options',
		[MariaDBOptions]::description,
		'Use default options?') {}

	[IQuestion]MakeQuestion([string] $prompt) {
		return new-object YesNoQuestion($prompt, 
			'Yes, I want to use default MariaDB options', 
			'No, I want to customize MariaDB', 0)
	}

	[bool]HandleResponse([IQuestion] $question) {
		$this.config.configureOptions = ([YesNoQuestion]$question).choice -eq 1

		if (-not $this.config.configureOptions) {
			$this.SetDefaultOptions()
		}
		return $true
	}

	[void]Reset() {
		$this.config.configureOptions = $false
		$this.SetDefaultOptions()
	}

	[void]SetDefaultOptions() {
		$this.config.characterSet = $this.defaultCharacterSet
		$this.config.collation = $this.defaultCollation
		$this.config.lowerCaseTableNames = $this.defaultLowerCaseTableNames
	}
}

class CharacterSet : Step {

	static [string] hidden $description = @'
Specify the MariaDB character set you want to use.
'@

	CharacterSet([ConfigInput] $config) : base(
		[CharacterSet].Name, 
		$config,
		'Character Set',
		[CharacterSet]::description,
		"Enter Character Set (e.g., $([MariaDBOptions]::defaultCharacterSet))") {}

	[bool]HandleResponse([IQuestion] $question) {
		$this.config.characterSet = ([Question]$question).GetResponse([MariaDBOptions]::defaultCharacterSet)
		return $true
	}

	[void]Reset(){
		$this.config.characterSet = [MariaDBOptions]::defaultCharacterSet
	}

	[bool]CanRun() {
		return $this.config.configureOptions
	}
}

class Collation : Step {

	static [string] hidden $description = @'
Specify the MariaDB collation you want to use.
'@

	Collation([ConfigInput] $config) : base(
		[Collation].Name, 
		$config,
		'Character Set',
		[Collation]::description,
		"Enter Character Set (e.g., $([MariaDBOptions]::defaultCollation))") {}

	[bool]HandleResponse([IQuestion] $question) {
		$this.config.collation = ([Question]$question).GetResponse([MariaDBOptions]::defaultCollation)
		return $true
	}

	[void]Reset() {
		$this.config.collation = [MariaDBOptions]::defaultCollation
	}

	[bool]CanRun() {
		return $this.config.configureOptions
	}
}

class TableNameCase : Step {

	static [string] hidden $description = @'
Specify the MariaDB table name case you want to use.
'@

	TableNameCase([ConfigInput] $config) : base(
		[TableNameCase].Name, 
		$config,
		'Table Name Case',
		[TableNameCase]::description,
		"Select table name case (e.g., $([MariaDBOptions]::defaultLowerCaseTableNames))") {}

	[IQuestion]MakeQuestion([string] $prompt) {

		$choices = @(
			[tuple]::create('Case-sensitive comparison', 'Use case-sensitive comparison for table/database names'),
			[tuple]::create('Lowercase with case-insensitive comparison', 'Use lowercase names for table/database names with case-insensitive comparison'),
			[tuple]::create('As declared with lowercase comparison', 'Use table/database names as declared with lowercase comparison')
		)

		return new-object MultipleChoiceQuestion($this.prompt, $choices, -1)
	}

	[bool]HandleResponse([IQuestion] $question) {
		$this.config.lowerCaseTableNames = ([MultipleChoiceQuestion]$question).choice
		return $true
	}

	[void]Reset() {
		$this.config.lowerCaseTableNames = [MariaDBOptions]::defaultLowerCaseTableNames
	}

	[bool]CanRun() {
		return $this.config.configureOptions
	}
}
