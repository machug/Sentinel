$MIGuid = "<GUID>"
$SubscriptionId = "<SUBID>"
$ResourceGroupName = "<RG>"

Connect-AzureAD

$MI = Get-AzureADServicePrincipal -ObjectId $MIGuid
$GraphAppId = "00000003-0000-0000-c000-000000000000"
$roleName = "Password Administrator"
$SentinelRoleName = "Microsoft Sentinel Responder"
$PermissionName = "User.ReadWrite.All" 

$GraphServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$GraphAppId'"

#Grant Azure AD Password Administrator role
$role = Get-AzureADDirectoryRole | Where {$_.displayName -eq $roleName}
if ($role -eq $null) {
$roleTemplate = Get-AzureADDirectoryRoleTemplate | Where {$_.displayName -eq $roleName}
Enable-AzureADDirectoryRole -RoleTemplateId $roleTemplate.ObjectId
$role = Get-AzureADDirectoryRole | Where {$_.displayName -eq $roleName}
}
Add-AzureADDirectoryRoleMember -ObjectId $role.ObjectId -RefObjectId $MI.ObjectID

#Grant Resource Group Sentinel Responder role
New-AzRoleAssignment -ObjectId $MIGuid -RoleDefinitionName $SentinelRoleName -Scope /subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupName

#Grant Azure AD Permissions
$AppRole = $GraphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains "Application"}
New-AzureAdServiceAppRoleAssignment -ObjectId $MI.ObjectId -PrincipalId $MI.ObjectId `
-ResourceId $GraphServicePrincipal.ObjectId -Id $AppRole.Id
