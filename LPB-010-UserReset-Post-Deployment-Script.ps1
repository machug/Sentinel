param (
    [parameter(Mandatory = $true)][string]$MIGuid, # Managed Identity GUID
    [parameter(Mandatory = $true)][string]$SubscriptionId, # Subscription ID
    [parameter(Mandatory = $true)][string]$ResourceGroupName # Resource Group Name
)
Install-Module AzureAD -Force
$context = Get-AzContext

if (!$context) {
    Connect-AzAccount
    $context = Get-AzContext
}

$MI = Get-AzADServicePrincipal -ObjectId $MIGuid
$roleName = "Password Administrator"
$SentinelRoleName = "Microsoft Sentinel Responder"
$PermissionName = "User.ReadWrite.All" 

$GraphServicePrincipal = Get-AzAdServicePrincipal -ApplicationId "00000003-0000-0000-c000-000000000000"

#Grant Azure AD Password Administrator role
$role = Get-AzureADDirectoryRole | ? { $_.displayName -eq $roleName }
if ($role -eq $null) {
    $roleTemplate = Get-AzureADDirectoryRoleTemplate | ? { $_.displayName -eq $roleName }
    Enable-AzureADDirectoryRole -RoleTemplateId $roleTemplate.ObjectId
    $role = Get-AzureADDirectoryRole | ? { $_.displayName -eq $roleName }
}
Add-AzureADDirectoryRoleMember -ObjectId $role.ObjectId -RefObjectId $MI.ObjectID

#Grant Resource Group Sentinel Responder role
New-AzRoleAssignment -ObjectId $MIGuid -RoleDefinitionName $SentinelRoleName -Scope /subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupName

#Grant Azure AD Permissions
$AppRole = $GraphServicePrincipal.AppRoles | ? { $_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains "Application" }
New-AzureAdServiceAppRoleAssignment -ObjectId $MI.ObjectId -PrincipalId $MI.ObjectId -ResourceId $GraphServicePrincipal.ObjectId -Id $AppRole.Id
