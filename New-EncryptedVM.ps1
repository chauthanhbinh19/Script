# For more info: https://learn.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-powershell-quickstart 
# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/disk-encryption-key-vault-aad

#region Azure Login
Connect-AzAccount 
#endregion 

#region Variables
$ResourceGroupName = "cclab-21521176"
$VMName = "EncryptWin1"
$Location = "East Asia"
$Subnet1Name = "default"
$VNetName = "Encrypt-VNet"
$InterfaceName = $VMName + "-NIC"
$PublicIPName = $VMName + "-PIP"
$ComputerName = $VMName
$VMSize = "Standard_B2ms"
$username = "adminvm"
$password = "admin123456@"
$StorageName = "ccstorage" + $ResourceGroupName.replace("-","").replace('cclab',"").ToLower()
$StorageType = "Standard_LRS"
$OSDiskName = $VMName + "OSDisk"
$OSPublisherName = "MicrosoftWindowsServer"
$OSOffer = "WindowsServer"
$OSSKu = "2019-Datacenter"
$OSVersion = "latest"
#endregion 

#region AAD app
############################## Create Azure AD application ##############################

$aadAppName = $("MyApp1" + "-" + $ResourceGroupName)
$aadClientID = ""
$aadClientSecret = ""
# Create a new AD application
Write-Host "Creating a new AD Application: $aadAppName..."
$now = [System.DateTime]::Now
$oneYearFromNow = $now.AddYears(1)
$ADApp =  New-AzADApplication -DisplayName $aadAppName -StartDate $now -EndDate $oneYearFromNow
$credential = New-Object -TypeName "Microsoft.Azure.PowerShell.Cmdlets.Resources.MSGraph.Models.ApiV10.MicrosoftGraphPasswordCredential" -Property @{'DisplayName' = 'labPassword';}
$appCredential = New-AzADAppCredential -ObjectId $ADapp.Id
$aadClientSecret = $appCredential.SecretText
$servicePrincipal = New-AzADServicePrincipal -ApplicationId $ADApp.AppId -Role Contributor
$aadClientID = $servicePrincipal.AppId
Write-Host "Successfully created a new AAD Application: $aadAppName with ID: $aadClientID"
#endregion

#region KeyVault
############################## Create and Deploy the KeyVault and Keys ##############################
$keyVaultName = $("MyKeyVault1" + "-" + $ResourceGroupName)
# Create Key Vault
Write-Host "Creating the KeyVault: $keyVaultName..."
$keyVault = New-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $ResourceGroupName -Sku Standard -Location $Location -EnabledForDiskEncryption;
$keyVault = Get-AzKeyVault -VaultName $keyVaultName -ResourceGroupName  $ResourceGroupName;
$keyVaultResourceId = $keyVault.ResourceId
$diskEncryptionKeyVaultUrl = $keyVault.VaultUri

# Set the permissions required to enable the DiskEncryption Policy
Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ResourceGroupName $ResourceGroupName -EnabledForDiskEncryption
Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ServicePrincipalName $aadClientID -PermissionsToKeys get,list,encrypt,decrypt,create,import,sign,verify,wrapKey,unwrapKey -PermissionsToSecrets get,list,set -ResourceGroupName $ResourceGroupName

# Create the KeyEncryptionKey (KEK)
$keyEncryptionKeyName = $("MyKey1" + "-" + $ResourceGroupName)
Write-Host "Creating the KeyEncryptionKey (KEK): $keyEncryptionKeyName..."
Add-AzKeyVaultKey -VaultName $keyVaultName -Name $keyEncryptionKeyName -Destination Software
$keyEncryptionKeyUrl = (Get-AzKeyVaultKey -VaultName $KeyVaultName -Name $keyEncryptionKeyName).Key.kid
# Output the values of the KeyVault
Write-Host "KeyVault values that will be needed to enable encryption on the VM" -foregroundcolor Green
Write-Host "KeyVault Name: $keyVaultName" -foregroundcolor Green
Write-Host "aadClientID: $aadClientID" -foregroundcolor Green
Write-Host "aadClientSecret: $aadClientSecret" -foregroundcolor Green
Write-Host "diskEncryptionKeyVaultUrl: $diskEncryptionKeyVaultUrl" -foregroundcolor Green
Write-Host "keyVaultResourceId: $keyVaultResourceId" -foregroundcolor Green
Write-Host "keyEncryptionKeyURL: $keyEncryptionKeyUrl" -foregroundcolor Green
#endregion

#region VM
############################## Create and Deploy the VM ###############################
# Create storage account
Write-Host "Creating storage account: $StorageName..."
$StorageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -SkuName $StorageType -Location $Location

# Create a Public IP
Write-Host "Creating a Public IP: $PublicIPName..."
$publicIP = New-AzPublicIpAddress -Name $PublicIPName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic

# Create the VNet
Write-Host "Creating a VNet: $VNetName..."
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix "192.168.1.0/24"
$VNet = New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix "192.168.0.0/16" -Subnet $subnetConfig
$myNIC = New-AzNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $publicip.Id

# Create the VM Credentials
Write-Host "Creating VM Credentials..."
$secureStringPwd = $password | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $secureStringPwd

# Create the basic VM config
Write-Host "Creating the basic VM config..."
$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -ComputerName $ComputerName -Windows -Credential $Credential -ProvisionVMAgent
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $myNIC.Id

# Create OS Disk Uri and attach it to the VM
Write-Host "Creating the OSDisk '$OSDiskName' for the VM..."
$NewOSDiskVhdUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName.ToLower() + "-" + $osDiskName + '.vhd'
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $OSPublisherName -Offer $OSOffer -Skus $OSSKu -Version $OSVersion
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name $osDiskName -VhdUri $NewOSDiskVhdUri -CreateOption FromImage

# Create the VM
Write-Host "Building the VM: $VMName..."
New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine
#endregion 


#region Encryption Extension
############################## Deploy the VM Encryption Extension ###############################
# Build the encryption extension
Write-Host "Deploying the VM Encryption Extension..."
Set-AzVMDiskEncryptionExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId -VolumeType "OS" -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $keyVaultResourceId -Force
#endregion

############################## Verify the encryption process ##############################
Get-AzVmDiskEncryptionStatus -VMName $VMName -ResourceGroupName $ResourceGroupName
