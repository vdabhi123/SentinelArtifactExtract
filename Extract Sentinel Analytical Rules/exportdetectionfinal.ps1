# Install and import YAML module (if not already present)
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Install-Module -Name powershell-yaml -Scope CurrentUser -Force
}
Import-Module powershell-yaml

# Define GitHub base URL and solutions
$baseUrl = "https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Solutions"
$solutions = @(
    "Azure Activity",
    "Microsoft Defender XDR",
    "Microsoft Entra ID",
    "Threat Intelligence"
)

# Temp array to store all rules
$allRules = @()

foreach ($solution in $solutions) {
    $encodedSolution = $solution -replace ' ', '%20'
    $apiUrl = "https://api.github.com/repos/Azure/Azure-Sentinel/contents/Solutions/$encodedSolution/Analytic%20Rules"

    try {
        $ruleFiles = Invoke-RestMethod -Uri $apiUrl

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
    } catch {
        Write-Warning "⚠️ Failed to fetch rules from $apiUrl. Error: $($_.Exception.Message)"
    }
}

# Export to CSV with UTF8 encoding
$csvPath = "./Sentinel_Analytics_Rules.csv"
$allRules | Export-Csv -Path $csvPath -NoTypeInformation -Encoding utf8

Write-Host "`n✅ Exported $($allRules.Count) rules to $csvPath"
