#Requires -Modules Microsoft.Graph
# Install the module. (You need admin on the machine.)
# Install-Module Microsoft.Graph

# Set Static Variables
# Your tenant
$TenantID="UPDATE"
# The LogicApp name you created the Managed Identiy in
$ServicePrincipalAppDisplayName ="LPB-013-ServiceNow-MDE"

# Define dynamic variables
$ServicePrincipalFilter = "displayName eq '$($ServicePrincipalAppDisplayName)'" 
$GraphAPIAppName = "WindowsDefenderATP"
$ApiServicePrincipalFilter = "displayName eq '$($GraphAPIAppName)'"

# Scopes needed for the managed identity (Add other scopes if needed)
$Scopes = @(
    "Alert.ReadWrite.All"
    "Machine.ReadWrite.All"
)

# Connect to MG Graph - scopes must be consented the first time you run this. 
# Connect with Global Administrator
Connect-MgGraph -Scopes "Application.Read.All","AppRoleAssignment.ReadWrite.All"  -TenantId $TenantID -UseDeviceAuthentication

# Get the service principal for your managed identity.
$ServicePrincipal = Get-MgServicePrincipal -Filter $ServicePrincipalFilter

# Get the service principal for Microsoft Graph. 
# Result should be the AppId 
$ApiServicePrincipal = Get-MgServicePrincipal -Filter "$ApiServicePrincipalFilter"

# Apply permissions
Foreach ($Scope in $Scopes) {
    Write-Host "`nGetting App Role '$Scope'"
    $AppRole = $ApiServicePrincipal.AppRoles | Where-Object {$_.Value -eq $Scope -and $_.AllowedMemberTypes -contains "Application"}
    if ($null -eq $AppRole) { Write-Error "Could not find the specified App Role on the Api Service Principal"; continue; }
    if ($AppRole -is [array]) { Write-Error "Multiple App Roles found that match the request"; continue; }
    Write-Host "Found App Role, Id '$($AppRole.Id)'"

    $ExistingRoleAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipal.Id | Where-Object { $_.AppRoleId -eq $AppRole.Id }
    if ($null -eq $existingRoleAssignment) {
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipal.Id -PrincipalId $ServicePrincipal.Id -ResourceId $ApiServicePrincipal.Id -AppRoleId $AppRole.Id
    } else {
        Write-Host "App Role has already been assigned, skipping"
    }
} 
