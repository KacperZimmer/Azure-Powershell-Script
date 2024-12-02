#Requires -Modules Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Users

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.SignIns

Connect-MgGraph -Scopes 'User.ReadWrite.All'

$applicationId = ""

$extensionName = "snowApp"


function UpdateUserProfileAndAddExtension {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InvitedUserId,
        [Parameter(Mandatory = $true)]
        [string]$CustomValue,
        [Parameter(Mandatory = $true)]
        [string]$CompanyNumber
    )


    $extensions = Get-MgApplicationExtensionProperty -ApplicationId $applicationId
    $matchingExtension = $extensions | Where-Object { $_.Name -match $extensionName }
    if (-not $matchingExtension) {
        Write-Host "Nie znaleziono rozszerzenia " + $extensionName + ". Tworzenie nowego rozszerzenia..."
        $params = @{
            Name         = $extensionName
            DataType     = "String"
            TargetObjects = @("User")
        }
        $matchingExtension = New-MgApplicationExtensionProperty -ApplicationId $applicationId -BodyParameter $params
        Write-Host "Utworzono nowe rozszerzenie: $($matchingExtension.Name)"
    }

    $companyNumberExtension = $extensions | Where-Object { $_.Name -match "companyNumber" }
    if (-not $companyNumberExtension) {
        Write-Host "Nie znaleziono rozszerzenia 'companyNumber'. Tworzenie nowego rozszerzenia..."
        $params = @{
            Name         = "companyNumber"
            DataType     = "String"
            TargetObjects = @("User")
        }
        $companyNumberExtension = New-MgApplicationExtensionProperty -ApplicationId $applicationId -BodyParameter $params
        Write-Host "Utworzono nowe rozszerzenie: $($companyNumberExtension.Name)"
    }


    Write-Host "Aktualizowanie profilu użytkownika..."
    Update-MgUser -UserId $InvitedUserId `
                  -JobTitle "Software Developer" `
                  -Department "IT Department" `
                  -CompanyName "YourCompanyName"


    $snowAppData = @{
        $matchingExtension.Name = $CustomValue
    }
    Write-Host "Dodawanie właściwości apps"
    Update-MgUser -UserId $InvitedUserId -AdditionalProperties $snowAppData


    $companyNumberData = @{
        $companyNumberExtension.Name = $CompanyNumber
    }
    Write-Host "Dodawanie właściwości companyNumber"
    Update-MgUser -UserId $InvitedUserId -AdditionalProperties $companyNumberData
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
                UpdateUserProfileAndAddExtension -InvitedUserId $invitation.InvitedUser.Id -CustomValue ($User.Applications -join ", ") -CompanyNumber ($User.CompanyNumber)
            }
        } catch {
            Write-Host "Błąd przy wysyłaniu zaproszenia do: $($User.Email). Szczegóły: $_" -ForegroundColor Red
        }
    }
}


$usersToInvite = @(
    @{ Email = "user1@example.com"; Name = "User One"; Applications = @("App32", "App23"); CompanyNumber = "123456" },
    @{ Email = "user2@example.com"; Name = "User Two"; Applications = @("App3", "App4"); CompanyNumber = "789012" }
)
$redirectUrl = "https://myapplications.microsoft.com"


Send-MgInvitations -UserList $usersToInvite -RedirectUrl $redirectUrl
