
Import-Module Microsoft.Graph


Connect-MgGraph -Scopes "User.Invite.All"


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
                -SendInvitationMessage: $true

            Write-Host "Zaproszenie wysłane do: $($User.Email) (ID zaproszenia: $($invitation.Id))" -ForegroundColor Green
        } catch {
            Write-Host "Błąd przy wysyłaniu zaproszenia do: $($User.Email). Szczegóły: $_" -ForegroundColor Red
        }
    }
}

$usersToInvite = @(
    @{ Email = "user1@example.com"; Name = "User One" },
    @{ Email = "user2@example.com"; Name = "User Two" },
    @{ Email = "user3@example.com"; Name = "User Three" }
)

Send-MgInvitations -UserList $usersToInvite -RedirectUrl "https://myapplications.microsoft.com/"