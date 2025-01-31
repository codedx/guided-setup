Set-PSDebug -Strict

###############################################################################
# data-structures.ps1 (begin)
###############################################################################

class Comparator {
	hidden [scriptblock]$compare
	hidden [scriptblock]$compareOriginal

	Comparator() {
		$this.compare = {
			param($a, $b)

			if ($a -eq $b) { return 0 }
			if ($a -lt $b) { return -1 }

			return 1
		}
	}

	Comparator([scriptblock]$compareFunction) {
		$this.compare = $compareFunction
	}

	[int] equal($a, $b) {
		return (& $this.compare $a $b) -eq 0
	}

	[int] lessThan($a, $b) {
		return (& $this.compare $a $b) -lt 0
	}

	[int] greaterThan($a, $b) {
		return (& $this.compare $a $b) -gt 0
	}

	[int] lessThanOrEqual($a, $b) {
		return $this.lessThan($a, $b) -Or $this.equal($a, $b)
	}

	[int] greaterThanOrEqual($a, $b) {
		return $this.greaterThan($a, $b) -Or $this.equal($a, $b)
	}

	reverse() {
		$this.compareOriginal = $this.compare

		$this.compare = {
			param($a, $b)

			&$this.compareOriginal $b $a
		}
	}
}

# https://github.com/trekhleb/javascript-algorithms/tree/master/src/data-structures/linked-list

class LinkedListNode {
	$value
	$next

	LinkedListNode($value) {
		$this.value = $value
	}

	LinkedListNode($value, $next) {
		$this.value = $value
		$this.next = $next
	}

	[string]ToString() {
		return $this.value
	}
}

class LinkedList {
	$head
	$tail
	$compare

	# default ctor
	LinkedList() {
		$this.compare = New-Object Comparator
	}

	LinkedList($comparatorFunction) {
		$this.compare = New-Object Comparator $comparatorFunction
	}

	[object] Append($value) {
		$newNode = New-Object LinkedListNode $value

		# If there is no head yet let's make new node a head.
		if (!$this.head) {
			$this.head = $newNode
			$this.tail = $newNode
			return $this
		}

		# Attach new node to the end of linked list.
		$this.tail.next = $newNode
		$this.tail = $newNode

		return $this
	}

	[object] Prepend($value) {
		#  Make new node to be a head.
		$this.head = New-Object LinkedListNode $value, $this.head
		return $this
	}

	hidden [object] Find($value, [scriptblock]$callback) {
		if (!$this.head) {
			return $null
		}

		$currentNode = $this.head

		while ($currentNode) {

			if ($callback -and (&$callback $currentNode.value)) {
				return $currentNode
			}

			if ($null -ne $value -and $this.compare.equal($currentNode.value, $value)) {
				return $currentNode
			}

			$currentNode = $currentNode.next
		}

		return $null
	}

	[object] deleteHead() {
		if (!$this.head) {
			return $null
		}

		$deletedHead = $this.head

		if ($this.head.next) {
			$this.head = $this.head.next
		}
		else {
			$this.head = $null
			$this.tail = $null
		}

		return $deletedHead;
	}

	[object] deleteTail() {
		if ($this.head -eq $this.tail) {
			$deletedTail = $this.tail
			$this.head = $null
			$this.tail = $null

			return $deletedTail
		}

		$deletedTail = $this.tail

		# Rewind to the last node and delete "next" link for the node before the last one.
		$currentNode = $this.head
		while ($currentNode.next) {
			if (!$currentNode.next.next) {
				$currentNode.next = $null
			}
			else {
				$currentNode = $currentNode.next
			}
		}

		$this.tail = $currentNode
		return $deletedTail
	}

	[object] Delete($value) {
		if (!$this.head) {
			return $null
		}

		$deletedNode = $null

		# If the head must be deleted then make 2nd node to be a head.
		while ($this.head -and ($this.head.value -eq $value)) {
			$deletedNode = $this.head
			$this.head = $this.head.next
		}

		$currentNode = $this.head

		if ($null -ne $currentNode) {
			# If next node must be deleted then make next node to be a next next one.
			while ($currentNode.next) {
				if ($currentNode.next.value -eq $value) {
					$deletedNode = $currentNode.next
					$currentNode.next = $currentNode.next.next
				}
				else {
					$currentNode = $currentNode.next
				}
			}
		}

		# Check if tail must be deleted.
		if ($this.tail.value -eq $value) {
			$this.tail = $currentNode
		}

		return $deletedNode
	}

	[object] ToArray() {
		$nodes = @()
		$currentNode = $this.head
		while ($currentNode) {
			$nodes += ($currentNode)
			$currentNode = $currentNode.next
		}

		return $nodes
	}

	[string] ToString() {
		return $this.ToString($null)
	}

	[string] ToString($callback) {
		return ($this.ToArray() -join ",")
	}
}

class GraphEdge {

	$startVertex
	$endVertex
	$weight

	GraphEdge($startVertex, $endVertex) {
		$this.DoInit($startVertex, $endVertex, 0)
	}

	GraphEdge($startVertex, $endVertex, $weight) {
		$this.DoInit($startVertex, $endVertex, $weight)
	}

	hidden DoInit($startVertex, $endVertex, $weight) {
		$this.startVertex = $startVertex
		$this.endVertex = $endVertex
		$this.weight = $weight
	}

	[object] getKey() {
		$startVertexKey = $this.startVertex.getKey()
		$endVertexKey = $this.endVertex.getKey()

		return "$($startVertexKey)_$($endVertexKey)"
		# return `${startVertexKey}_${endVertexKey}`;
	}

	[object] reverse() {
		$tmp = $this.startVertex
		$this.startVertex = $this.endVertex
		$this.endVertex = $tmp

		return $this
	}


	[string] toString() {
		return $this.getKey()
	}
}

class GraphVertex {
	$value
	$edges

	GraphVertex() {
		$this.DoInit($null)
	}

	GraphVertex($value) {
		$this.DoInit($value)
	}

	hidden DoInit($value) {
		if ($null -eq $value) {
			throw 'Graph vertex must have a value'
		}

		$edgeComparator = {
			param($edgeA, $edgeB)

			if ($edgeA.getKey() -eq $edgeB.getKey()) {
				return 0
			}

			if ($edgeA.getKey() -lt $edgeB.getKey()) { return -1 }

			return 1
		}

		# Normally you would store string value like vertex name.
		# But generally it may be any object as well
		$this.value = $value
		$this.edges = New-Object LinkedList $edgeComparator
	}

	[object] addEdge($edge) {
		$this.edges.append($edge)

		return $this
	}

	deleteEdge($edge) {
		$this.edges.delete($edge)
	}

	[object] getNeighbors() {
		$targetEdges = $this.edges.toArray()

		$neighborsConverter = {
			param($node)

			if ($node.value.startVertex -eq $this) {
				return $node.value.endVertex
			}

			return $node.value.startVertex
		}

		# Return either start or end vertex.
		# For undirected graphs it is possible that current vertex will be the end one.
		return @($targetEdges.ForEach{&$neighborsConverter $_})
	}

	[object] getEdges() {
		return $this.edges.toArray().value
	}


	[object] getDegree() {
		return $this.edges.toArray().Count
	}

	[bool] hasEdge($requiredEdge) {
		$edgeNode = $this.edges.find($null, {
				param($edge)
				$edge -eq $requiredEdge
			})

		return !!$edgeNode
	}

	[object] hasNeighbor($vertex) {
		$vertexNode = $this.edges.find($null, {
				param($edge)

				$edge.startVertex -eq $vertex -or $edge.endVertex -eq $vertex
			})

		return !!$vertexNode
	}

	[object] findEdge($vertex) {
	  $edgeFinder ={
		  param($edge)

		  return $edge.startVertex -eq $vertex -Or $edge.endVertex -eq $vertex
	  };

	  $targetEdge = $this.edges.find($null, $edgeFinder)

	  if($targetEdge) {
		return $targetEdge.value
	  }

	  return $null
	}

	[object] getKey() {
		return $this.value
	}

	[object] deleteAllEdges() {

		foreach ($edge in $this.getEdges()) {
			$this.deleteEdge($edge)
		}

		return $this
	}

	[string] toString() {
		return $this.toString($null)
	}

	[string] toString($callback) {

		if ($callback) {
			return &$callback($this.value)
		}

		return $this.value -join '_'
	}
}

class Graph {
	$vertices
	$edges
	[bool]$isDirected

	Graph () {
		$this.DoInit($false)
	}

	Graph ($isDirected) {
		$this.DoInit($isDirected)
	}

	DoInit($isDirected) {
		$this.vertices = [Ordered]@{}
		$this.edges = [Ordered]@{}
		$this.isDirected = $isDirected
	}

	[object] addVertex($newVertex) {
		$this.vertices[$newVertex.getKey()] = $newVertex
		return $this
	}

	[object] getVertexByKey($vertexKey) {
		return $this.vertices[$vertexKey]
	}

	[object] getNeighbors($vertex) {
		return $vertex.getNeighbors()
	}

	[object[]] getAllVertices() {
		return $this.vertices.values
	}

	[object[]] getAllEdges() {
		return $this.edges.values
	}

	[object] addEdge($edge) {
		# Try to find and end start vertices.
		$startVertex = $this.getVertexByKey($edge.startVertex.getKey())
		$endVertex = $this.getVertexByKey($edge.endVertex.getKey())

		# Insert start vertex if it wasn't inserted.
		if (!$startVertex) {
			$this.addVertex($edge.startVertex)
			$startVertex = $this.getVertexByKey($edge.startVertex.getKey())
		}

		# Insert end vertex if it wasn't inserted.
		if (!$endVertex) {
			$this.addVertex($edge.endVertex)
			$endVertex = $this.getVertexByKey($edge.endVertex.getKey())
		}

		# Check if edge has been already added.
		if ($this.edges[$edge.getKey()]) {
			throw 'Edge has already been added before'
		}
		else {
			$this.edges[$edge.getKey()] = $edge
		}

		# Add edge to the vertices.
		if ($this.isDirected) {
			# If graph IS directed then add the edge only to start vertex.
			$startVertex.addEdge($edge)
		}
		else {
			# If graph ISN'T directed then add the edge to both vertices.
			$startVertex.addEdge($edge)
			$endVertex.addEdge($edge)
		}

		return $this
	}

	deleteEdge($edge) {
		# Delete edge from the list of edges.
		if ($this.edges[$edge.getKey()]) {
			$this.edges.Remove($edge.getKey())
		}
		else {
			throw 'Edge not found in graph'
		}

		# Try to find and end start vertices and delete edge from them.
		$startVertex = $this.getVertexByKey($edge.startVertex.getKey())
		$endVertex = $this.getVertexByKey($edge.endVertex.getKey())

		$startVertex.deleteEdge($edge)
		$endVertex.deleteEdge($edge)
	}

	[object] findEdge($startVertex, $endVertex) {
		$vertex = $this.getVertexByKey($startVertex.getKey())
		return $vertex.findEdge($endVertex)
	}

	[Object] findVertexByKey($vertexKey) {
		if ($this.vertices[$vertexKey]) {
			return $this.vertices[$vertexKey]
		}

		return $null
	}

	[object] getWeight() {
		$weight = 0
		foreach ($graphEdge in $this.getAllEdges()) {
			$weight += $graphEdge.weight
		}

		return $weight
	}

	[object] reverse() {

		foreach ($edge in $this.getAllEdges()) {
			# Delete straight edge from graph and from vertices.
			$this.deleteEdge($edge)

			# Reverse the edge.
			$edge.reverse()

			# Add reversed edge back to the graph and its vertices.
			$this.addEdge($edge)
		}

		return $this
	}

	[System.Collections.Specialized.OrderedDictionary] getVerticesIndices() {
		$verticesIndices = [Ordered]@{}

		$allVertices = $this.getAllVertices()

		for ($idx = 0; $idx -lt $allVertices.Count; $idx += 1) {
			$item = $allVertices[$idx]
			$verticesIndices.($item.getKey()) = $idx
		}

		return $verticesIndices
	}

	[object] getAdjacencyMatrix() {
		$targetVertices = $this.getAllVertices()
		$verticesIndices = $this.getVerticesIndices()

		#   # Init matrix with infinities meaning that there is no ways of
		#   # getting from one vertex to another yet.

		$adjacencyMatrix = (0..($targetVertices.Count)).ForEach{New-Object object[] ($targetVertices.Count)}

		for ($outer = 0; $outer -le $targetVertices.Count; $outer += 1) {
			for ($inner = 0; $inner -le $targetVertices.Count - 1; $inner += 1) {
				$adjacencyMatrix[$outer][$inner] = [double]::PositiveInfinity
			}
		}

		# Fill the columns.
		for ($vertexIndex = 0; $vertexIndex -le $targetVertices.Count - 1; $vertexIndex += 1) {
			$vertex = $targetVertices[$vertexIndex]

			foreach ($neighbor in $vertex.getNeighbors()) {
				$neighborIndex = $verticesIndices[$neighbor.getKey()]
				$adjacencyMatrix[$vertexIndex][$neighborIndex] = $this.findEdge($vertex, $neighbor).weight
			}
		}

		return $adjacencyMatrix
	}

	[string] toString() {
		return $this.vertices.keys -join ","
	}
}

###############################################################################
# data-structures.ps1 (end)
###############################################################################

# Note: PowerShell doesn't support declaring an interface
class IQuestion { 
	[void]Prompt() {
		throw [NotImplementedException] 
	}
}

class Question : IQuestion {

	[string] $promptText

	[bool]   $hasResponse
	[bool]   $isResponseEmpty
	[string] $response

	[bool]   $isSecure
	[string] $validationExpr
	[string] $validationHelp
	[int]    $minimumLength
	[int]    $maximumLength

	[string[]] $blacklist

	[bool]   $allowEmptyResponse
	[string] $emptyResponseLabel = 'Accept Default'
	[string] $emptyResponseHelp = 'Use default value by providing no response'
	
	static [string] hidden $returnQuestionLabel = 'Return to Step'
	static [string] hidden $previousStepLabel = 'Back to Previous Step'

	Question([string] $promptText) {
		$this.promptText = $promptText
	}

	[void]Prompt() {
		
		[string] $result = ''
		while ($true) {

			$result = Read-HostText $this.promptText $this.minimumLength $this.maximumLength $this.blacklist $this.isSecure $this.validationExpr $this.validationHelp -allowBlankEntry
			if ($result -ne '') {
				break
			}

			$options = @()
			if ($this.allowEmptyResponse) {
				$options += [tuple]::Create($this.emptyResponseLabel, $this.emptyResponseHelp)
			}
			$options += @(
				[tuple]::Create([question]::returnQuestionLabel, 'Provide a response to the question'),
				[tuple]::Create([question]::previousStepLabel,  'Go back to the previous step')
			)
			$choice = Read-HostChoice 'What do you want to do?' $options

			if (($options[$choice]).item1 -eq $this.emptyResponseLabel) {
				$this.isResponseEmpty = $true
				break
			}

			if (($options[$choice]).item1 -eq [question]::previousStepLabel) {
				$this.hasResponse = $false
				$this.response = ''
				return
			}
		}

		$this.hasResponse = $true
		$this.response = $result
	}

	[string] GetResponse([string] $whenEmpty) {
		if (!$this.hasResponse) {
			return $null
		}
		return $this.isResponseEmpty ? $whenEmpty : $this.response
	}
}

class ConfirmationQuestion : Question {

	ConfirmationQuestion([string] $promptText) : base($promptText) {
	}

	[void]Prompt() {

		$prompt = $this.promptText

		while ($true) {
		
			([Question]$this).Prompt()
			if (-not $this.hasResponse -or $this.isResponseEmpty) {
				break
			}
			$response = $this.response
			
			$this.promptText = 'Confirm'
			$this.response = ''

			([Question]$this).Prompt()
			if (-not $this.hasResponse -or $this.isResponseEmpty -or $response -eq $this.response) {
				break
			}
			
			Write-Host 'Responses do not match. Try again.'
			$this.promptText = $prompt
			$this.response = ''
		}
		$this.promptText = $prompt
	}
}

class IntegerQuestion : Question {

	[int] $minimum
	[int] $maximum

	[int]  $intResponse

	IntegerQuestion([string] $promptText, [int] $minimum, [int] $maximum, [bool] $allowEmptyResponse) : base($promptText) {

		if ($minimum -gt $maximum) {
			throw "Unexpected min/max values - $minimum is greater than $maximum."
		}

		$this.minimum = $minimum
		$this.maximum = $maximum
		$this.allowEmptyResponse = $allowEmptyResponse
		$this.validationExpr = "^\d+$"
		$this.validationHelp = "Enter a number between $minimum and $maximum."
	}

	[void]Prompt() {

		while ($true) {
			([Question]$this).Prompt()

			if (-not $this.hasResponse) {
				return
			}

			if ($this.isResponseEmpty) {
				break
			}

			[int] $val = 0
			if ([Int]::TryParse($this.response, [ref]$val)) {

				if ($val -lt $this.minimum -or $val -gt $this.maximum) {
					Write-Host $this.validationHelp
					continue
				}
				$this.intResponse = $val
				break
			}
		}
	}
}

class PathQuestion : Question {

	[bool] $isDirectory

	PathQuestion([string] $promptText, [bool] $isDirectory, [bool] $allowEmptyResponse) : base($promptText) {
		$this.isDirectory = $isDirectory
		$this.allowEmptyResponse = $allowEmptyResponse
	}

	[void]Prompt() {

		while ($true) {
			([Question]$this).Prompt()

			if (-not $this.hasResponse) {
				return
			}

			if ($this.isResponseEmpty) {
				break
			}

			$pathType = 'Leaf'
			if ($this.isDirectory) {
				$pathType = 'Container'
			}

			if (Test-Path $this.response -PathType $pathType) {
				break
			}

			$path = $this.response.Trim("'").Trim('"')
			if (Test-Path $path -PathType $pathType) {
				$this.response = $path
				break
			}

			$pathTypeMessage = 'file'
			if ($this.isDirectory) {
				$pathTypeMessage = 'directory'
			}
			Write-Host "Unable to read $pathTypeMessage '$($this.response)' - the $pathTypeMessage may not exist or you may not have permissions to read it - please enter another $pathTypeMessage path"
		}
	}
}

class CertificateFileQuestion : PathQuestion {

	CertificateFileQuestion([string] $promptText, [bool] $allowEmptyResponse) : base($promptText, $false, $allowEmptyResponse) {
	}

	[void]Prompt() {

		while ($true) {
			([PathQuestion]$this).Prompt()

			if (-not $this.hasResponse) {
				return
			}

			if ($this.isResponseEmpty) {
				break
			}

			if (Test-KeyToolCertificate $this.response) {
				break
			}
			Write-Host "Unable to read certificate file '$($this.response)' - does the file contain a certificate?"
		}
	}
}

class EmailAddressQuestion : Question {

	EmailAddressQuestion([string] $promptText, [bool] $allowEmptyResponse) : base($promptText) {
		$this.allowEmptyResponse = $allowEmptyResponse
	}

	[void]Prompt() {

		while ($true) {
			([Question]$this).Prompt()

			if (-not $this.hasResponse) {
				return
			}

			if ($this.isResponseEmpty) {
				break
			}

			if (Test-EmailAddress $this.response) {
				break
			}
			Write-Host "'$($this.response)' is an invalid email address."
		}
	}
}

class MultipleChoiceQuestion : IQuestion {

	[string] $promptText
	[tuple`2[string,string][]] $options
	[int] $defaultOption

	[bool] $hasResponse
	[int]  $choice

	MultipleChoiceQuestion([string] $promptText, [tuple`2[string,string][]] $options, [int] $defaultOption) {
		$this.promptText = $promptText
		$this.options = $options
		$this.options += [tuple]::Create([question]::previousStepLabel, 'Go back to the previous step')
		$this.defaultOption = $defaultOption
	}

	[void]Prompt() {
		$this.choice = Read-HostChoice $this.promptText $this.options $this.defaultOption
		$this.hasResponse = $this.options[$this.choice].item1 -ne [question]::previousStepLabel
	}
}

class YesNoQuestion : MultipleChoiceQuestion {

	YesNoQuestion([string] $promptText, [string] $yesHelp, [string] $noHelp, [int] $defaultOption) : base($promptText, @(
		[tuple]::Create('Yes', $yesHelp),
		[tuple]::Create('No', $noHelp)
	), $defaultOption) {}
}

class GuidedSetupStep : GraphVertex {

	[string]      $name

	[string]      $title
	[string]      $message
	[string]      $prompt

	GuidedSetupStep([string]      $name, 
		 [string]      $title,
		 [string]      $message,
		 [string]      $prompt) : base($name) {

		$this.name = $name
		$this.title = $title
		$this.message = $message
		$this.prompt = $prompt
	}

	[bool]CanRun() {
		return $true
	}

	[bool]Run() {

		Write-HostSection $this.title ($this.GetMessage())

		$footer = $this.GetMessageFooter()
		if ("" -ne $footer) {
			Write-Host $footer
			Write-Host
		}

		while ($true) {
			$question = $this.MakeQuestion($this.prompt)
			$question.Prompt()
			
			if (-not $question.hasResponse) {
				return $false
			}
	
			if ($this.HandleResponse($question)) {
				break
			}
		}
		return $true
	}

	[IQuestion]MakeQuestion([string]$prompt) {
		return new-object Question($prompt)
	}

	[bool]HandleResponse([IQuestion] $question) {
		throw [NotImplementedException]
	}

	[string]GetMessage() {
		return $this.message
	}

	[string]GetMessageFooter() {
		return ""
	}

	[void]Reset() {
		
	}

	[void]ApplyDefault() {
		throw [NotImplementedException]
	}

	[string]GetDefault() {
		return ''
	}

	[void]Delay() {
		Start-Sleep -Seconds 1
	}

	[object]toString() {
		return $this.name
	}
}

Get-ChildItem "$PSScriptRoot/functions" -Recurse -Include '*.ps1' | ForEach-Object {
	. $_
}

function Set-GuidedSetupModulePreferences([Management.Automation.ActionPreference] $errorPref, [Management.Automation.ActionPreference] $verbosePref) {
	Set-Variable -Scope "1" -Name 'ErrorActionPreference' -Value $errorPref
	Set-Variable -Scope "1" -Name 'VerbosePreference' -Value $verbosePref
}
Set-GuidedSetupModulePreferences ([Management.Automation.ActionPreference]::Stop) ([Management.Automation.ActionPreference]::Continue)