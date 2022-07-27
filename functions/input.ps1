<#PSScriptInfo
.VERSION 1.0.0
.GUID b9a28367-a806-4d33-936c-73f8dc9e522a
.AUTHOR Code Dx
.DESCRIPTION Includes input-related helpers
#>

function Read-HostEnter([string] $prompt='Press Enter to continue...') {
	Read-Host $prompt
}

function Write-HostSection([string] $title, [string] $message) {

	Write-Host $title -ForegroundColor White
	Write-Host 
	Write-Host $message
	Write-Host
}

function Read-HostChoice([string] $question, [tuple`2[string,string][]] $options, [int] $defaultOption) {

	if ($options.count -lt 2) {
		throw "Expected the options list for '$prompt' to contain at least two items."
	}

	$choices = @()
	$mnemonics = New-Object Collections.Generic.HashSet[string]
	$options | ForEach-Object {
		
		$choiceKey = $_.Item1
		$choiceMnemonic = $choiceKey.ToLower() | select-string -pattern '^[^&]*&(?<mnemonic>.)'
		if ($choiceMnemonic.Matches.Success) {
			# use provided mnemonic, even if it conflicts with another provided one
			$mnemonics.Add($choiceMnemonic.Matches.Groups[1].value) | out-null
		} else {
			# select an available mnemonic when one wasn't provided
			$chars = $choiceKey.ToLower().ToCharArray()
			for ($i = 0; $i -lt $chars.Length; $i++) {
				$char = $chars[$i]
				if ($char -notmatch '\W' -and -not $mnemonics.Contains($char)) {
					$mnemonics.Add($char) | out-null
					$choiceKey = '{0}&{1}' -f $choiceKey.Substring(0, $i),$choiceKey.Substring($i)
					break
				}
			}
		}
		$choices += New-Object Management.Automation.Host.ChoiceDescription($choiceKey, $_.Item2)
	}
	
	Write-Host "$question`n"
	(Get-Host).UI.PromptForChoice('', '', $choices, $defaultOption)
}