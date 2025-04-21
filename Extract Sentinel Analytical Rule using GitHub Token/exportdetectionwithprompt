# Install and import YAML module (if not already present)
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Install-Module -Name powershell-yaml -Scope CurrentUser -Force
}
Import-Module powershell-yaml

# Define GitHub base URL
$baseUrl = "https://api.github.com/repos/Azure/Azure-Sentinel/contents/Solutions"

# Fetch available solutions from the GitHub repository
try {
    $solutionsData = Invoke-RestMethod -Uri $baseUrl
    $availableSolutions = $solutionsData | Where-Object { $_.type -eq 'dir' } | Select-Object -ExpandProperty name
} catch {
    Write-Host "⚠️ Failed to fetch solution data from GitHub. Error: $($_.Exception.Message)"
    exit
}

# Filter out solutions that do not contain an "Analytic Rules" folder
$validSolutions = @()

foreach ($solution in $availableSolutions) {
    $encodedSolution = $solution -replace ' ', '%20'
    $apiUrl = "https://api.github.com/repos/Azure/Azure-Sentinel/contents/Solutions/$encodedSolution"
    
    try {
        # Fetch solution contents
        $solutionContent = Invoke-RestMethod -Uri $apiUrl

        # Check if the solution has an "Analytic Rules" folder (accounting for nested folder structure)
        $analyticRulesFolder = $solutionContent | Where-Object { $_.path -like "*Analytic Rules*" }

        if ($analyticRulesFolder) {
            $validSolutions += $solution
        }
    } catch {
        Write-Warning "⚠️ Failed to check for Analytic Rules in $solution. Error: $($_.Exception.Message)"
    }
}

# Display a nicely formatted list of valid solutions for user selection
Write-Host "`nHere are the available solutions with Analytic Rules:"
$validSolutions | ForEach-Object { Write-Host " - $_" }

# Prompt user to choose a solution from the available list
$solution = Read-Host "`nEnter the solution name from the above list"

# Validate if the entered solution is in the valid solutions list
if ($validSolutions -contains $solution) {
    $encodedSolution = $solution -replace ' ', '%20'
    $apiUrl = "https://api.github.com/repos/Azure/Azure-Sentinel/contents/Solutions/$encodedSolution/Analytic%20Rules"

    # Temp array to store all rules
    $allRules = @()

    try {
        # Fetch the analytic rules for the selected solution
        $ruleFiles = Invoke-RestMethod -Uri $apiUrl
        if ($ruleFiles) {
            foreach ($file in $ruleFiles | Where-Object { $_.name -like '*.yaml' }) {
                $fileUrl = $file.download_url
                try {
                    $yamlContent = Invoke-RestMethod -Uri $fileUrl
                    $parsedYaml = ConvertFrom-Yaml $yamlContent

                    $ruleName = $parsedYaml["name"]
                    $description = $parsedYaml["description"]
                    $severity = $parsedYaml["severity"]
                    $tactics = ($parsedYaml["tactics"] -join ", ")
                    $techniques = ($parsedYaml["relevantTechniques"] -join ", ")

                    $allRules += [PSCustomObject]@{
                        Solution         = $solution
                        RuleName         = $ruleName
                        Description      = $description
                        Severity         = $severity
                        MITRE_Tactics    = $tactics
                        MITRE_Techniques = $techniques
                    }
                } catch {
                    Write-Warning "⚠️ Failed to fetch or parse ${fileUrl}: $($_.Exception.Message)"
                }
            }
        } else {
            Write-Warning "⚠️ No analytic rules found for the solution '$solution'."
        }
    } catch {
        Write-Warning "⚠️ Failed to fetch rules from $apiUrl. Error: $($_.Exception.Message)"
    }

    # Export to CSV with UTF8 encoding only if there are rules
    if ($allRules.Count -gt 0) {
        $csvPath = "./Sentinel_Analytics_Rules_$($solution.Replace(' ', '_')).csv"
        $allRules | Export-Csv -Path $csvPath -NoTypeInformation -Encoding utf8
        Write-Host "`n✅ Exported $($allRules.Count) rules to $csvPath"
    } else {
        Write-Host "`n⚠️ No rules found for solution '$solution'."
    }
} else {
    Write-Host "⚠️ Invalid solution name entered. Please choose from the list."
}
