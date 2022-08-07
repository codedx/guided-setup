class Step : GuidedSetupStep {

	[ConfigInput] $config

	Step([string]      $name, 
		 [ConfigInput] $config,
		 [string]      $title,
		 [string]      $message,
		 [string]      $prompt) : base($name, $title, $message, $prompt) {

		$this.config = $config
	}
}