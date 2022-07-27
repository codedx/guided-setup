<#PSScriptInfo
.VERSION 1.0.0
.GUID fc6ce9ac-58ac-4e50-befb-754f063752f0
.AUTHOR Code Dx
.DESCRIPTION Includes Docker-related helpers
#>

function Split-DockerName([string] $dockerImageName, [switch] $name) {

	if (-not ($dockerImageName -match '^(?<name>.+):(?<tag>[^:]+)$')) {
		throw "Unable to find Docker image name and tag in $dockerImageName"
	}
	($matches[$name ? 'name' : 'tag']).trim()
}

function Split-DockerRepo([string] $dockerName, [switch] $repo) {

	$domain = 'docker.io'
	$name = $dockerName

	$i = $dockerName.IndexOf('/')
	if ($i -ne -1) {
		$str = $dockerName.Substring(0, $i)
		if ($str.Contains('.') -or $str.Contains(':')) {
			$domain = $str
			$name = $dockerName.Substring($i+1)
		}
	}
	return $repo ? $domain : $name
}

function Get-DockerImageParts([string] $dockerImageName) {

	$repo      = Split-DockerRepo $dockerImageName -repo
	$remainder = Split-DockerRepo $dockerImageName
	$name      = Split-DockerName $remainder -name
	$tag       = Split-DockerName $remainder

	@($repo, $name, $tag)
}
