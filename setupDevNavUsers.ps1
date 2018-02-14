# get all DEVs from AD and add them as NAV Server Users
$AdGroup = $env:DevGroup

Write-Host " - Importing ActiveDirectory PowerShell Module"
Add-WindowsFeature RSAT-AD-PowerShell
Import-Module ActiveDirectory

# Import NAV Module
Write-Host " - Importing NAV Module"
$nstFolder = (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Service").FullName
Import-Module (Join-Path $nstFolder 'Microsoft.Dynamics.Nav.Management.dll')

Write-Host " - Gettings users from AD group $AdGroup"
$users = Get-ADGroupMember -Identity $AdGroup | Sort-Object name

Write-Host " - Generate NAV User with SUPER permission for each user in AD group $AdGroup"
foreach($user in $users)
{
    if ($user.objectClass -eq "user") {
        $sid = $user.SID.Value;
        Write-Host ("    Adding " + $user.name)
    
        New-NAVServerUser -Sid $sid -ServerInstance NAV -ErrorAction Continue
        New-NAVServerUserPermissionSet -Sid $sid -ServerInstance NAV -PermissionSetId SUPER -ErrorAction Continue
    }
}
