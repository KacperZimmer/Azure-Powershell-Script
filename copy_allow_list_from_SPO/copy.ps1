
function GetObjectFromJson([string] $JsonString) {
    ConvertFrom-Json -InputObject $JsonString |
    ForEach-Object {
        foreach ($property in ($_ | Get-Member -MemberType NoteProperty)) {
            $_.$($property.Name) | Add-Member -MemberType NoteProperty -Name 'Name' -Value $property.Name -PassThru
        }
    }
}
function Set-B2BManagementPolicy {
    param (
        [string[]]$AllowList
    )


    $ExistingAllowList = GetExistingAllowedDomainList

    $AllowList = $AllowList + $ExistingAllowList

    if ($null -ne $ExistingAllowList) {
        Write-Host "`nSetting AllowDomainList for B2BManagementPolicy (APPEND).`n"

    }
    
    New-AzureADPolicy `
    -Definition $policyValue `
    -DisplayName 'B2BManagementPolicy' `
    -Type B2BManagementPolicy `
    -IsOrganizationDefault $true `
    -InformationAction Ignore | Out-Null
   
    $policyValue = GetJSONForAllowBlockDomainPolicy -AllowDomains $AllowList
    
}


function GetJSONForAllowBlockDomainPolicy([string[]] $AllowDomains = @(), [string[]] $BlockedDomains = @()) {

    $AllowDomains = $AllowDomains | Select-Object -uniq
    $BlockedDomains = $BlockedDomains | Select-Object -uniq

    return @{B2BManagementPolicy = @{InvitationsAllowedAndBlockedDomainsPolicy = @{AllowedDomains = @($AllowDomains); BlockedDomains = @($BlockedDomains) } } } | ConvertTo-Json -Depth 3 -Compress
}

function GetExistingAllowedDomainList() {
    $policy = $currentTenantPolicy = Get-AzureADPolicy -All $true | ?{$_.Type -eq 'B2BManagementPolicy'} | select -First 1

    if ($null -ne $policy) {
        $policyObject = GetObjectFromJson $policy.Definition[0];

        if ($null -ne $policyObject.InvitationsAllowedAndBlockedDomainsPolicy -and $null -ne $policyObject.InvitationsAllowedAndBlockedDomainsPolicy.AllowedDomains) {
            return $policyObject.InvitationsAllowedAndBlockedDomainsPolicy.AllowedDomains;
        }
    }
    return $null
} 


$allowedDomainsSPO = Get-SPOTenant | select -ExpandProperty SharingAllowedDomainList$allowedDomains 
Set-B2BManagementPolicy -AllowList $allowedDomainsSPO





