function Install-AzurePowerShell {
    $ProgressPreference = 'SilentlyContinue' # Ignore progress updates (100X speedup)
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module Az.Accounts -RequiredVersion 2.7.2 -Confirm:$false
    Install-Module Az.Resources -RequiredVersion 5.2.0 -Confirm:$false
    Install-Module Az.Compute -RequiredVersion 4.23.0 -Confirm:$false
    Install-Module Az.KeyVault -RequiredVersion 4.2.1 -Confirm:$false
    Install-Module Az.Network -RequiredVersion 4.14.0 -Confirm:$false
    Install-Module Az.Storage -RequiredVersion 4.2.0 -Confirm:$false
}


function Set-LabArtifacts {
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/chauthanhbinh19/Script/refs/heads/main/New-EncryptedVM.ps1" -OutFile C:\Users\adminvm\Desktop\New-EncryptedVM.ps1
    # Create backup
    $path = "C:\Scripts"
    if(!(Test-Path $path))
    {
        New-Item -ItemType Directory -Force -Path C:\Scripts
    }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/chauthanhbinh19/Script/refs/heads/main/New-EncryptedVM.ps1" -OutFile $($path + "\" + "New-EncryptedVM.ps1")

}

function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

function Disable-UserAccessControl {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 -Force
    Write-Host "User Access Control (UAC) has been disabled." -ForegroundColor Green    
}

Disable-UserAccessControl
Disable-InternetExplorerESC
Install-AzurePowerShell
Set-LabArtifacts
