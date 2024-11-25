#Requires -Modules Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Users

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.SignIns

# Connect to Microsoft Graph with appropriate permissions
Connect-MgGraph -Scopes 'User.ReadWrite.All'

# Enter the application ID
$applicationId = "<AppId>" # Enter the application ID (GUID)

# Retrieve all directory extensions for the given application
$extensions = Get-MgApplicationExtensionProperty -ApplicationId $applicationId

# Dynamically search for an extension ending with 'jobGroupTracker'
$matchingExtension = $extensions | Where-Object { $_.Name -match "jobGroupTracker$" }

# If the extension does not exist, create it
if (-not $matchingExtension) {
    Write-Host "The 'jobGroupTracker' extension was not found. Creating a new extension..."

    # Create a new extension
    $params = @{
        Name         = "jobGroupTracker"
        DataType     = "String"
        TargetObjects = @("User")
    }
    $newExtension = New-MgApplicationExtensionProperty -ApplicationId $applicationId -BodyParameter $params
    Write-Host "Created a new extension: $($newExtension.Name)"
    $matchingExtension = $newExtension
} else {
    Write-Host "Found an existing extension: $($matchingExtension.Name)"
}

# Create an invitation for a user
$invitation = New-MgInvitation -InvitedUserDisplayName "<DisplayName>" ` # Enter the display name
                               -InvitedUserEmailAddress "<EmailAddress>" ` # Enter the email address
                               -InviteRedirectUrl "<RedirectURL>" ` # Enter the redirect URL
                               -SendInvitationMessage: $true

if ($invitation -and $invitation.InvitedUser) {
    $invitedUserId = $invitation.InvitedUser.Id

    # Update the user's profile
    Update-MgUser -UserId $invitedUserId `
                  -JobTitle "<JobTitle>" ` # Enter the job title
                  -Department "<Department>" ` # Enter the department
                  -CompanyName "<CompanyName>" # Enter the company name

    # Dynamically create extension data for update
    $extensionData = @{
        $matchingExtension.Name = "<ExtensionValue>" # Enter the value for the extension
    }

    Write-Host "Adding a custom property to the user..."
    # Update the user's extension property
    Update-MgUser -UserId $invitedUserId -AdditionalProperties $extensionData

    Write-Host "The user has been successfully updated."

    # Check the custom property's value
    $user = Get-MgUser -UserId $invitedUserId -Property "id,displayName,extension_<ExtensionNamespace>_jobGroupTracker"

    Write-Host "The value of the custom property:"
    Write-Host $user.AdditionalProperties.'extension_<ExtensionNamespace>_jobGroupTracker' # Replace <ExtensionNamespace> with the correct namespace
} else {
    Write-Host "The invitation was not created successfully."
}
