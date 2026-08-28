$config = New-PesterConfiguration

$config.Run.Path = @(
    "$PSScriptRoot\Tests\Unit",
    "$PSScriptRoot\Tests\Integration"
)

$config.Run.Exit = $false

$config.Output.Verbosity = "Detailed"

$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = "$PSScriptRoot\Tests\testResults.xml"
$config.TestResult.OutputFormat = "NUnitXml"

$config
