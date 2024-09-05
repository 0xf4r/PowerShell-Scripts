# Connect to Exchange Online
Connect-ExchangeOnline -UserPrincipalName <YourAdminEmail> -ShowProgress $true

# Get all shared mailboxes
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited

# Create an array to store mailbox details
$sharedMailboxesDetails = @()

# Loop through each shared mailbox and get creation date
foreach ($mailbox in $sharedMailboxes) {
    # Fetch the mailbox statistics to get creation date
    $mailboxStats = Get-MailboxStatistics -Identity $mailbox.Alias
    
    # Create a custom object to store the necessary details
    $sharedMailboxInfo = [pscustomobject]@{
        DisplayName    = $mailbox.DisplayName
        PrimarySMTP    = $mailbox.PrimarySmtpAddress
        Alias          = $mailbox.Alias
        CreationDate   = $mailboxStats.WhenMailboxCreated
    }
    
    # Add to array
    $sharedMailboxesDetails += $sharedMailboxInfo
}

# Export the list to CSV
$sharedMailboxesDetails | Export-Csv -Path "C:\SharedMailboxesList.csv" -NoTypeInformation

# Disconnect session
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "Shared Mailbox list with creation date exported successfully!"
