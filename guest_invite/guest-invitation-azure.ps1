
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.SignIns


Connect-MgGraph -Scopes 'User.ReadWrite.All'


$invitation = New-MgInvitation -InvitedUserDisplayName "John Doe" `
                               -InvitedUserEmailAddress "johndoe@example.com" `
                               -InviteRedirectUrl "https://myapplications.microsoft.com" `
                               -SendInvitationMessage: $true


if ($invitation -and $invitation.InvitedUser) {
    
    $invitedUserId = $invitation.InvitedUser.Id

    Update-MgUser -UserId $invitedUserId `
                  -JobTitle "Software Developer" `
                  -Department "IT Department" `
                  -CompanyName "YourCompanyName"
} else {
    Write-Host "Zaproszenie nie zostało utworzone pomyślnie"
}
