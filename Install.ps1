Add-Type -AssemblyName System.Windows.Forms
$host.ui.RawUI.WindowTitle = "Steam Mods Update - Installer"

function Get-PathForThis {
    param(
        [string]$description
    )  
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $description
    $folderBrowser.RootFolder = "MyComputer"
    $folderBrowser.ShowNewFolderButton = $false
    [void]$folderBrowser.ShowDialog()
    return $folderBrowser.SelectedPath
}

function Write-Config {
    param(
        [string]$Message,
        [string]$ConfigFile
    )
    Add-content -Path $ConfigFile -Value $Message
}

$steamPath = Get-PathForThis -description "Select Steam folder"
if ($steamPath -eq "") {
    exit
}

$configFile = "SteamModsUpdate.config"
$steamcmdDownloadLink = "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
$gitbashDownloadLink = "https://github.com/git-for-windows/git/releases/download/v2.47.0.windows.2/Git-2.47.0.2-64-bit.exe"
$scriptSteamUpdateDownloadLink = "https://raw.githubusercontent.com/jonathanCarra/SteamModsUpdate/refs/heads/main/Steam%20Mods%20Update.sh"

New-Item -Name "Steam Mods Update" -Path $pwd.Path -ItemType Directory
Invoke-WebRequest $steamcmdDownloadLink -OutFile "$pwd\Steam Mods Update\steamcmd.zip"
Expand-Archive "$pwd\Steam Mods Update\steamcmd.zip" -DestinationPath "$pwd\Steam Mods Update\SteamCMD"
Start-Process "$pwd\Steam Mods Update\SteamCMD\steamcmd.exe" -ArgumentList "+quit" -NoNewWindow -Wait

Invoke-WebRequest $gitbashDownloadLink -OutFile "$pwd\Steam Mods Update\Git-2.47.0.2-64-bit.exe"
Start-Process "$pwd\Steam Mods Update\Git-2.47.0.2-64-bit.exe" -NoNewWindow -Wait

Write-Config -ConfigFile "$pwd\Steam Mods Update\$configFile" -Message $steamPath

Remove-Item "$pwd\Steam Mods Update\steamcmd.zip"
Remove-Item "$pwd\Steam Mods Update\Git-2.47.0.2-64-bit.exe"

Invoke-WebRequest $scriptSteamUpdateDownloadLink -OutFile "$pwd\Steam Mods Update\Steam Mods Update.sh"

pause