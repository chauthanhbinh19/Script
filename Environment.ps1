function Install-AzurePowerShell {
    $ProgressPreference = 'SilentlyContinue'  # Ignore progress updates (100X speedup)
    Install-PackageProvider -Name NuGet -Force -Confirm:$false
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module Az.Accounts -Confirm:$false
    Install-Module Az.Resources -Confirm:$false
    Install-Module Az.Compute -Confirm:$false
    Install-Module Az.KeyVault -Confirm:$false
    Install-Module Az.Network -Confirm:$false
    Install-Module Az.Storage -Confirm:$false
}


function Set-LabArtifacts {
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/chauthanhbinh19/Script/refs/heads/main/New-EncryptedVM.ps1" -OutFile C:\Users\student\Desktop\New-EncryptedVM.ps1
    # Create backup
    $path = "C:\Scripts"
    if(!(Test-Path $path))
    {
        New-Item -ItemType Directory -Force -Path C:\Scripts
    }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/chauthanhbinh19/Script/refs/heads/main/New-EncryptedVM.ps1" -OutFile $($path + "\" + "New-EncryptedVM.ps1")

}


Install-AzurePowerShell
Set-LabArtifacts
