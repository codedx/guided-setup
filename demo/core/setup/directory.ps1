function New-SetupWorkDirectory([string] $workDir,
	[string] $namespace,
	[string] $releaseName) {

	### Create work subdirectory
	$workDir = join-path $workDir "$namespace-$releaseName"
	Write-Verbose "Creating directory $workDir..."
	New-Item -Type Directory $workDir -Force

	### Switch to Work Directory
	Write-Verbose "Switching to directory $workDir..."
	Push-Location $workDir

	### Reset Resources directory
	$resourcesDir = './Resources'
	if (Test-Path $resourcesDir -PathType Container) {
		Remove-Item $resourcesDir -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
	}
}
