# Import the module
Import-Module powershell-yaml
Import-Module Az


# Convert the YAML content to a PowerShell object
$varParameters = ConvertFrom-Yaml -Yaml $(Get-Content -Path "./deployparam.yaml" -Raw)
$varParameters.add("varTimeStamp", (Get-Date).ToString("yyyy-MM-ddTHH.mm.ss"))

#constants
$conMaxRetryAttemptTransientErrorRetry = 3
$conRetry = $true
$conRetryWaitTimeTransientErrorRetry = 10
$conLoopCounter = 0

#bicep files
$biceptemplate = '.\deploy.bicep'

function Enter-Login {
    Write-Information ">>> Initiating a login" -InformationAction Continue
    Connect-AzAccount
}

function Get-SignedInUser {

    $varSignedInUserDetails = Get-AzADUser -SignedIn

    if (!$varSignedInUserDetails) {
        Write-Information ">>> No logged in user found." -InformationAction Continue
    }
    else {
        return $varSignedInUserDetails.UserPrincipalName
    }

    return $null

}

# function Confirm-UserOwnerPermission {
#     if ($null -ne $varSignedInUser) {

#         $subscriptionId = $varParameters.subscriptionId
#         $varSignedInUser = $varSignedInUserDetails.UserPrincipalName
#         Set-AzContext -subscriptionId $subscriptionId
#         Write-Information "`n>>> Checking the owner permissions for user: $varSignedInUser at $subscriptionId scope"  -InformationAction Continue
#         $roleAssignments  = Get-AzRoleAssignment -ObjectId $varSignedInUserDetails.Id -Scope "/subscriptions/$subscriptionId" -ErrorAction SilentlyContinue
#         $hasContributorRole = $roleAssignments | Where-Object {
#             $_.RoleDefinitionName -eq "Contributor" -or $_.RoleDefinitionName -eq "Owner"
#         }

#         if (!$hasContributorRole) {
#             Write-Information "Signed in user: $varSignedInUser does not have sufficient permission to the /subscriptions/$subscriptionId scope."  -InformationAction Continue
#             Write-Information "Permissions assigned: $roleAssignments"  -InformationAction Continue
#             return $false
#         }
#         else {
#             Write-Information "Signed in user: $varSignedInUser has sufficient permissions at the root /subscriptions/$subscriptionId scope."  -InformationAction Continue
#         }
#         return $true
#     }
#     else {
#         Write-Error "Logged in user details are empty." -ErrorAction Stop
#     }
# }

function New-ASRDemo {
    param()

    $parDeploymentPrefix = $varParameters.bicepParam.parDeploymentPrefix
    $parTimeStamp = $varParameters.varTimeStamp
    $parDeploymentLocation = $varParameters.bicepParam.sourceLocation
    $biceptemplateDeploymentName = "$parDeploymentPrefix-deploy-$partimeStamp"
    $parameters = @{
        parDeploymentPrefix = $varParameters.bicepParam.parDeploymentPrefix
        sourceLocation      = $varParameters.bicepparam.sourceLocation
        targetLocation      = $varParameters.bicepParam.targetLocation
        vmadminPassword     = $varParameters.bicepParam.vmAdminPassword
        sourceVnetConfig    = $varParameters.bicepParam.sourceVnetConfig
        targetVnetConfig    = $varParameters.bicepParam.targetVnetConfig
    }

    Set-AzContext -subscription $varParameters.subscriptionId

    while ($conLoopCounter -lt $conMaxRetryAttemptTransientErrorRetry) {
        try {
            Write-Information ">>> ASR Demo deployment started" -InformationAction Continue
            $bicepdeployment = New-AzSubscriptionDeployment `
                -Name $biceptemplateDeploymentName `
                -Location $parDeploymentLocation `
                -TemplateFile $biceptemplate `
                -parDeploymentPrefix $parameters.parDeploymentPrefix `
                -TemplateParameterObject $parameters `
                -WarningAction Ignore

            if (!$bicepdeployment -or $bicepdeployment.ProvisioningState -eq "Failed") {
                Write-Error "Error while executing ASR Demo deployment script" -ErrorAction Stop
            }

            return $bicepdeployment
        }
        catch {
            $conLoopCounter++
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            Write-Error "$varException \n $varErrorDetails \n $varTrace" -ErrorAction Continue

            if ($conRetry -and $conLoopCounter -lt $conMaxRetryAttemptTransientErrorRetry) {
                Write-Information ">>> Retrying deployment after waiting for $conRetryWaitTimeTransientErrorRetry secs" -InformationAction Continue
                Start-Sleep -Seconds $conRetryWaitTimeTransientErrorRetry
            }
            else {
                Write-Error ">>> Error occurred in Lighthouse deployment. Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
        }
    }
}

Enter-Login
New-ASRDemo