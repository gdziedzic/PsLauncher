function Fire
{
    param (
        [string]
        $command,
        [boolean]
        $copyContentToClipboardParam
    )

    if ($copyContentToClipboardParam)
    {
        $command | Set-Clipboard
        return
    }

    if ($command.StartsWith("www") -or $command.StartsWith("http"))
    {
        Start-Process $command
    }
    else
    {
        Invoke-Item $command
    }
}


function GetLaunchableProperty
{
    param (
        $item
    )
    
    return $item.Command
}

function GetMatchesForSinglePartQuery
{
    param (
        $inputJson,
        $prop,
        $query
    )
    
    return $inputJson | ? { ($null -ne $_.$prop) -and ($_.$prop.Contains($query, [System.stringcomparison]::ordinalignorecase)) }
}

function GetMatchesForMultipleParts
{
    param (
        $inputJson,
        $prop,
        $queryParts
    )

    $multiPartResults = [System.Collections.ArrayList]@()

    for ($i = 0; $i -lt $inputJson.Count; $i++)
    {
        $propertyValue = $inputJson[$i].$prop
        if ($null -eq $propertyValue)
        {
            continue;
        }

        if (($queryParts | % { $propertyValue.Contains($_, [System.StringComparison]::OrdinalIgnoreCase) }) -notcontains $false)
        {
            $multiPartResults.Add($inputJson[$i]) | Out-Null
        }
    }

    Write-Warning $multiPartResults.Count

    return $multiPartResults
}

function Launch
{
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$query,
        [Alias("r")]
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 1)]
        [int]$runThisOne = 0,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 2)]
        [switch]$justList = $true,
        [Alias("c")]
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [switch]$copyContentToClipboard = $false
    )

    $props = @('Command', 'Description')

    $configContent = Get-Content .\pslauncher.json
    $configJson = $configContent | ConvertFrom-Json

    enum QueryMode { Unknown = 0; Single = 1; Multi = 9 }
    [QueryMode]$mode = [QueryMode]::Unknown

    $results = [System.Collections.ArrayList]@()

    if ($query.Contains(" "))
    {
        $mode = [QueryMode]::Multi
        $queryParts = $query.Split(" ")
    }
    else
    {
        $mode = [QueryMode]::Single
    }

    for ($i = 0; $i -lt $props.Count; $i++)
    {
        $prop = $props[$i]
        if ($mode -eq [QueryMode]::Single)
        {
            $matchedItems = GetMatchesForSinglePartQuery -prop $prop -query $query -inputJson $configJson
        }
        else
        {
            $matchedItems = GetMatchesForMultipleParts -prop $prop -queryParts $queryParts -inputJson $configJson
        }

        foreach ($item In $matchedItems)
        {
            $launchableProperty = GetLaunchableProperty($item)
            if (-not ($results -contains $launchableProperty))
            {
                $results.add($launchableProperty) | Out-null
            }
        }
    }

    for ($i = 0; $i -lt $results.Count; $i++)
    {
        $form = $i + 1
        $x = $results[$i]
        Write-Output "$form. $x"
    }

    if ((-not $justList) -and ($results -ne $null) -and ($results.count -eq 1) -and ($mode -eq [QueryMode]::Single))
    {
        Fire $results[0] $copyContentToClipboard.IsPresent
    }

    if ($runThisOne -gt 0)
    {
        $index = $runThisOne - 1
        Fire $results[$index] $copyContentToClipboard.IsPresent
    }
}
