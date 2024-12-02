
$applicationId = ""
$extensions = Get-MgApplicationExtensionProperty -ApplicationId $applicationId | Where-Object {$_.Name -match "snow"}
$extensions