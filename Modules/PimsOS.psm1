# Managers
# --------------------------------------------------

. "$PSScriptRoot\Managers\PackageManager.ps1"
. "$PSScriptRoot\Managers\DriverManager.ps1"
. "$PSScriptRoot\Managers\FeatureManager.ps1"
. "$PSScriptRoot\Managers\CapabilityManager.ps1"
. "$PSScriptRoot\Managers\CommandManager.ps1"
. "$PSScriptRoot\Managers\FileManager.ps1"
. "$PSScriptRoot\Managers\FolderManager.ps1"
. "$PSScriptRoot\Managers\EnvironmentManager.ps1"
. "$PSScriptRoot\Managers\ScheduledTaskManager.ps1"
. "$PSScriptRoot\Managers\ShortcutManager.ps1"

# --------------------------------------------------
# Package Providers
# --------------------------------------------------

. "$PSScriptRoot\Package\Chocolatey.ps1"
. "$PSScriptRoot\Package\ChocolateyCache.ps1"
. "$PSScriptRoot\Package\Winget.ps1"

# --------------------------------------------------
# Windows
# --------------------------------------------------

. "$PSScriptRoot\Windows\Registry.ps1"

# --------------------------------------------------
# Image
# --------------------------------------------------
