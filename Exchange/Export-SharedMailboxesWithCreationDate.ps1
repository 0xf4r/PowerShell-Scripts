# Exchange Online shared mailbox export
# Connect to Exchange Online (Run this from a machine with the Exchange Online PowerShell Module installed)
$UserCredential = Get-Credential
Connect-ExchangeOnline -UserPrincipalName $UserCredential.UserName -Password $UserCredential.Password

# Fetch shared mailboxes and export to CSV
$SharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox | ForEach-Object {
    $Owners = Get-MailboxPermission -Identity $_.Alias | Where-Object { $_.AccessRights -eq "FullAccess" } | ForEach-Object { $_.User }
    $Members = Get-RecipientPermission -Identity $_.Alias | ForEach-Object { $_.Trustee }
    $LastActivity = Get-MailboxActivityReport -Identity $_.Alias | Select-Object -ExpandProperty LastActivityDate

    [PSCustomObject]@{
        MailboxName    = $_.DisplayName
        SMTPAddress    = $_.PrimarySmtpAddress
        Alias          = $_.Alias
        Owners         = ($Owners -join ",")
        Members        = ($Members -join ",")
        CreationDate   = $_.WhenCreated
        LastActivity   = $LastActivity
    }
}

$SharedMailboxes | Export-Csv -Path "C:\Temp\SharedMailboxes_Online.csv" -NoTypeInformation

# Disconnect Exchange Online session
Disconnect-ExchangeOnline -Confirm:$false

# Exchange On-Prem shared mailbox export (Run this from an Exchange Management Shell on-premise)
$SharedMailboxesOnPrem = Get-Mailbox -RecipientTypeDetails SharedMailbox | ForEach-Object {
    $Owners = Get-MailboxPermission -Identity $_.Alias | Where-Object { $_.AccessRights -eq "FullAccess" } | ForEach-Object { $_.User }
    $Members = Get-RecipientPermission -Identity $_.Alias | ForEach-Object { $_.Trustee }
    $CreationDate = Get-MailboxStatistics -Identity $_.Alias | Select-Object -ExpandProperty WhenMailboxCreated
    $LastActivity = Get-MailboxStatistics -Identity $_.Alias | Select-Object -ExpandProperty LastLogonTime

    [PSCustomObject]@{
        MailboxName    = $_.DisplayName
        SMTPAddress    = $_.PrimarySmtpAddress
        Alias          = $_.Alias
        Owners         = ($Owners -join ",")
        Members        = ($Members -join ",")
        CreationDate   = $CreationDate
        LastActivity   = $LastActivity
    }
}

$SharedMailboxesOnPrem | Export-Csv -Path "C:\Temp\SharedMailboxes_OnPrem.csv" -NoTypeInformation
