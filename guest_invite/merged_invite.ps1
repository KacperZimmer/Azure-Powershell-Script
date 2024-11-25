Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.SignIns


Connect-MgGraph -Scopes 'User.Invite.All, User.ReadWrite.All'


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

                UpdateUserProfileAndAddExtension -InvitedUserId $invitation.InvitedUser.Id -CustomValue "ExampleValue"
            }
        } catch {
            Write-Host "Błąd przy wysyłaniu zaproszenia do: $($User.Email). Szczegóły: $_" -ForegroundColor Red
        }
    }
}


function UpdateUserProfileAndAddExtension {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InvitedUserId,
        [Parameter(Mandatory = $true)]
        [string]$CustomValue
    )


    $applicationId = "<AppId>" 


    $extensions = Get-MgApplicationExtensionProperty -ApplicationId $applicationId


    $matchingExtension = $extensions | Where-Object { $_.Name -match "jobGroupTracker$" }
    if (-not $matchingExtension) {
        Write-Host "Rozszerzenie 'jobGroupTracker' nie zostało znalezione. Tworzę nowe..."
        $params = @{
            Name         = "jobGroupTracker"
            DataType     = "String"
            TargetObjects = @("User")
        }
        $newExtension = New-MgApplicationExtensionProperty -ApplicationId $applicationId -BodyParameter $params
        Write-Host "Utworzono nowe rozszerzenie: $($newExtension.Name)"
        $matchingExtension = $newExtension
    } else {
        Write-Host "Znaleziono istniejące rozszerzenie: $($matchingExtension.Name)"
    }


    try {
        Update-MgUser -UserId $InvitedUserId `
                      -JobTitle "Sample Job Title" `
                      -Department "Sample Department" `
                      -CompanyName "Sample Company"


        $extensionData = @{
            $matchingExtension.Name = $CustomValue
        }

        Write-Host "Dodawanie niestandardowej właściwości do użytkownika..."
        Update-MgUser -UserId $InvitedUserId -AdditionalProperties $extensionData

        Write-Host "Profil użytkownika został pomyślnie zaktualizowany."
    } catch {
        Write-Host "Błąd podczas aktualizacji profilu użytkownika: $_" -ForegroundColor Red
    }
}


$usersToInvite = @(
    @{ Email = "user1@example.com"; Name = "User One" },
    @{ Email = "user2@example.com"; Name = "User Two" },
    @{ Email = "user3@example.com"; Name = "User Three" }
)


Send-MgInvitations -UserList $usersToInvite -RedirectUrl "https://myapplications.microsoft.com/"
