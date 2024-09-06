# ASR Demo Lab

To deploy, edit the parameters and variables in asrlab.bicep to fit your needs, then run the following commands:

**Azure CLI**
```bash
# Prompt for the region
read -p "Enter the region shortname: " deploymentRegion
read -p "Enter the subscriptionId: " subscriptionId

# Run the Azure CLI Command
az deployment sub create --location $deploymentRegion --template-file asrlab.bicep --subscription $subscriptionId --parameters myhomeip=$(curl -s https://ipinfo.io/ip)
```

**PowerShell**
```powershell
# Prompt for a value
$deploymentRegion = Read-Host -Prompt "Enter the region shortname"
$subscriptionId = Read-Host -Prompt "Enter the subscription Id"

#Set current subscription scope
Set-AzContext -subscriptionId $subscriptionId

# Get the public IP address
$parameters = @{
    myhomeip = (Invoke-RestMethod -Uri "https://ipinfo.io/ip").Trim()
}

# Run the PowerShell command
New-AzSubscriptionDeployment -Location $deploymentRegion -TemplateFile ./asrlab.bicep -TemplateParameterObject $parameters
```
