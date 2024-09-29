function Install-AzurePowerShell {
    $ProgressPreference = 'SilentlyContinue'
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
    $ProgressPreference = 'SilentlyContinue' # Ignore progress updates (100X speedup)
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" # Support tls 1.1, 1.2 (PS uses 1.0 by default)
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/cloudacademy/azure-lab-provisioners/master/keyvault-diskencryption-lab/New-EncryptedVM.ps1" -OutFile C:\Users\student\Desktop\New-EncryptedVM.ps1
    # Create backup
    $path = "C:\Scripts"
    if(!(Test-Path $path))
    {
        New-Item -ItemType Directory -Force -Path C:\Scripts
    }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/cloudacademy/azure-lab-provisioners/master/keyvault-diskencryption-lab/New-EncryptedVM.ps1" -OutFile $($path + "\" + "New-EncryptedVM.ps1")

}


Install-AzurePowerShell
Set-LabArtifacts
