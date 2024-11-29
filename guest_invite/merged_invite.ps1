#Requires -Modules Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Users

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.SignIns

Connect-MgGraph -Scopes 'User.ReadWrite.All'

$applicationId = ""

$extensionName = "companyNumber"



function UpdateUserProfileAndAddExtension {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InvitedUserId,
        [Parameter(Mandatory = $true)]
        [string]$CustomValue
    )


    $extensions = Get-MgApplicationExtensionProperty -ApplicationId $applicationId
    $matchingExtension = $extensions | Where-Object { $_.Name -match $extensionName }
    $extensionAdname = $matchingExtension | Select-Object -Property Name

    if (-not $matchingExtension) {
        Write-Host "Nie znaleziono rozszerzenia " $extensionName "Tworzenie nowego rozszerzenia..."
        $params = @{
            Name         = $extensionName
            DataType     = "String"
            TargetObjects = @("User")
        }
        $matchingExtension = New-MgApplicationExtensionProperty -ApplicationId $applicationId -BodyParameter $params
        Write-Host "Utworzono nowe rozszerzenie: $($matchingExtension.Name)"
    }
    Write-Host "Znaleziono rozszerzenia " $extensionName "Tworzenie nowego rozszerzenia..."

    Update-MgUser -UserId $InvitedUserId `
                  -JobTitle "Software Developer" `
                  -Department "IT Department" `
                  -CompanyName "YourCompanyName"


    $extensionData = @{
        $matchingExtension.Name = $CustomValue
    }

    Write-Host "Dodawanie niestandardowej właściwości użytkownikowi..."
    Update-MgUser -UserId $InvitedUserId -AdditionalProperties $extensionData


}

function Send-MgInvitations {
    param (
        [Parameter(Mandatory = $true)]
        [array]$UserList,
        [Parameter(Mandatory = $true)]
        [string]$RedirectUrl
    )

    foreach ($User in $UserList) {
        $messageInfo = @{
            MessageLanguage = "en-US"
            CustomizedMessageBody = "You have been invited to access the application. Click the link to accept the invitation."
        }

        try {
            $invitation = New-MgInvitation `
                -InvitedUserEmailAddress $User.Email `
                -InvitedUserDisplayName $User.Name `
                -InviteRedirectUrl $RedirectUrl `
                -InvitedUserMessageInfo $messageInfo `
                -SendInvitationMessage:$true

            Write-Host "Zaproszenie wysłane do: $($User.Email) (ID zaproszenia: $($invitation.Id))" -ForegroundColor Green

            if ($invitation -and $invitation.InvitedUser) {
                Start-Sleep -Seconds 3
                UpdateUserProfileAndAddExtension -InvitedUserId $invitation.InvitedUser.Id -CustomValue ($User.CompanyNumber)
            }
        } catch {
            Write-Host "Błąd przy wysyłaniu zaproszenia do: $($User.Email). Szczegóły: $_" -ForegroundColor Red
        }
    }
}


$usersToInvite = @(
    @{ Email = "user1@example.com"; Name = "User One"; CompanyNumber = "companyNumber" },
    @{ Email = "user2@example.com"; Name = "User Two"; CompanyNumber = "companyNumber" }
)

$redirectUrl = "https://myapplications.microsoft.com"


Send-MgInvitations -UserList $usersToInvite -RedirectUrl $redirectUrl
