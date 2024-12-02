#Requires -Modules Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Users

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.SignIns

Connect-MgGraph -Scopes 'User.ReadWrite.All'







$applicationId = ""

# Pobranie wszystkich rozszerzeń katalogu dla danej aplikacji
$extensions = Get-MgApplicationExtensionProperty -ApplicationId $applicationId
$arrayOfValues = 'app1', 'app2'

$testValueString = $array -join " "




# Dynamiczne wyszukiwanie rozszerzenia, które kończy się na 'jobGroupTracker'
$matchingExtension = $extensions | Where-Object { $_.Name -match "jobGroupTracker$" }

# Jeśli rozszerzenie nie istnieje, tworzymy je
if (-not $matchingExtension) {
    Write-Host "Nie znaleziono rozszerzenia 'jobGroupTracker'. Tworzenie nowego rozszerzenia..."

    # Tworzenie nowego rozszerzenia
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

# Tworzenie zaproszenia dla użytkownika
$invitation = New-MgInvitation -InvitedUserDisplayName "John Doe" `
                               -InvitedUserEmailAddress "johndoe@example.com" `
                               -InviteRedirectUrl "https://myapplications.microsoft.com" `
                               -SendInvitationMessage: $true

if ($invitation -and $invitation.InvitedUser) {
    $invitedUserId = $invitation.InvitedUser.Id

    # Aktualizacja danych użytkownika
    Update-MgUser -UserId $invitedUserId `
                  -JobTitle "Software Developer" `
                  -Department "IT Department" `
                  -CompanyName "YourCompanyName"

    # Dynamicznie tworzymy dane rozszerzenia do aktualizacji
    $extensionData = @{
        $matchingExtension.Name = $arrayOfValues -join ", "
    }

    Write-Host "Dodawanie niestandardowej właściwości użytkownikowi..."
    # Aktualizacja rozszerzenia użytkownika
    Update-MgUser -UserId $invitedUserId -AdditionalProperties $extensionData

    Write-Host "Użytkownik został pomyślnie zaktualizowany."

    $user = Get-MgUser -UserId $invitedUserId -Property "id,displayName,extension_a4c92a8124844d02b1731a10eceb2691_jobGroupTracker"

        Write-Host "Wartość niestandardowej właściwości:"
        Write-Host $user.AdditionalProperties.'extension_a4c92a8124844d02b1731a10eceb2691_jobGroupTracker'
} else {
    Write-Host "Zaproszenie nie zostało utworzone pomyślnie."
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

                UpdateUserProfileAndAddExtension -InvitedUserId $invitation.InvitedUser.Id -CustomValue "ExampleValue"
            }
        } catch {
            Write-Host "Błąd przy wysyłaniu zaproszenia do: $($User.Email). Szczegóły: $_" -ForegroundColor Red
        }
    }
}