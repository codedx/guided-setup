<#PSScriptInfo
.VERSION 1.0.0
.GUID 30b223d9-c262-4631-9e29-c6ee8191dc26
.AUTHOR Code Dx
.DESCRIPTION Includes graph-related helpers.
#>

function Add-Step([Graph] $graph, [Step] $step) {

	$graph.addVertex($step) | out-null
}

function Add-StepTransition([Graph] $graph, [Step] $from, [Step] $to) {

	Write-Debug "Adding step transition from $($from.name) to $($to.name)..."
	foreach ($neighbor in $from.getNeighbors()) {
		if ($neighbor.name -eq $to.name) {
			return
		}
	}
	$graph.addEdge([GraphEdge]::new($from, $to)) | out-null
}

function Add-StepTransitions([Graph] $graph, [Step] $from, [Step[]] $toSteps) {

	for ($i = 0; $i -lt $toSteps.count; $i++) {
		$from = $i -eq 0 ? $from : $toSteps[$i-1]
		$to = $toSteps[$i]
		Add-StepTransition $graph $from $to
	}
}

function Clear-HostStep() {
	if ($DebugPreference -ne 'Continue') {
		Clear-Host
		$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0,5
	}
}

function Write-StepGraph([string] $path, [hashtable] $steps, [collections.stack] $stepsVisited) {

	"# Enter graph at https://dreampuf.github.io/GraphvizOnline (select 'dot' Engine and use Format 'png-image-element')`ndigraph G {`n" | out-file $path -force

	$linksVisited = New-Object Collections.Generic.HashSet[string]
	
	$previousStep = $null
	while ($stepsVisited.count -gt 0) {

		$step = $stepsVisited.pop()
		"$step [color=blue];" | out-file $path -append

		if ($null -eq $previousStep) {
			$previousStep = $step
			continue
		}
		
		$link = "$step -> $previousStep"
		"$link [color=blue];" | out-file $path -append

		$linksVisited.add($link) | out-null
		$previousStep = $step
	}

	$steps.keys | ForEach-Object {
		$node = $steps[$_]
		$node.getNeighbors() | ForEach-Object {
			$link = "$node -> $_"
			if (-not $linksVisited.Contains($link)) {
				"$link;" | out-file $path -append
			}
		}
	}

	"}" | out-file $path -append
}

function Invoke-GuidedSetup([string] $title, $beginState, $endStates) {

	$Host.UI.RawUI.WindowTitle = $title

	$v = $beginState
	$vStack = new-object collections.stack

	$edgeInfo = @()
	while ($true) {

		Clear-HostStep
		Write-Debug "`Previous Edges`: $edgeInfo; Running: $($v.Name)..."
		$edgeInfo = @()

		if (-not $v.Run()) {
			$v.Reset()
			if ($vStack.Count -ne 0) {
				$v = $vStack.Pop()
				$v.Reset()
			}
			continue
		}
		$vStack.Push($v)

		if ($endStates -contains $v) {
			break
		}

		$edges = $v.getEdges()
		if ($null -eq $edges) {
			throw "Unexpectedly found 0 edges associated with step $($v.Name)"
		}

		$edges | ForEach-Object {
			$edgeInfo += " $($_.endVertex) ($($_.endVertex.CanRun()))"
		}

		$next = $edges | Where-Object { $_.endVertex.CanRun() } | Select-Object -First 1 -ExpandProperty 'endVertex'
		if ($null -eq $next) {
			Write-Error "Found 0 next steps from $v, options included $($v.getNeighbors())."
		}
		$v = $next
	}
	$vStack
}
