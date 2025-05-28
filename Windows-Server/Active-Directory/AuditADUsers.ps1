# Audit-ADUsers.ps1
# Purpose: Extract user account details from Active Directory for auditing unused accounts
# Author: 0xf4r
# Date: May 28, 2025

# Import required module
Import-Module ActiveDirectory

# Configurable parameters
$Domain = "DC=example,DC=com"  # Modify this to your domain
$OUPath = ""  # Leave empty for entire domain or specify OU like "OU=Users,DC=example,DC=com"
$OutputCSV = Join-Path -Path $PSScriptRoot -ChildPath "ADUserAudit_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$LogFile = Join-Path -Path $PSScriptRoot -ChildPath "ADUserAudit_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Function to write to log file
function Write-Log {
    param($Message)
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    try {
        Add-Content -Path $LogFile -Value $LogMessage -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to extract OU path from DistinguishedName
function Get-OUPath {
    param($DistinguishedName)
    # Split DN by commas and filter out CN and DC components
    $components = $DistinguishedName -split ','
    $ouComponents = $components | Where-Object { $_ -like 'OU=*' }
    if ($ouComponents) {
        return $ouComponents -join ','
    }
    return ""
}

# Start logging
Write-Log "Starting AD user audit script"
Write-Log "Script directory: $PSScriptRoot"

# Verify output directory is accessible
try {
    if (-not (Test-Path -Path $PSScriptRoot -PathType Container)) {
        throw "Script directory ($PSScriptRoot) is not accessible."
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

try {
    # Determine search base
    $SearchBase = if ($OUPath) { $OUPath } else { $Domain }
    Write-Log "Querying users from SearchBase: $SearchBase"

    # Get AD users
    $Users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties SamAccountName,DisplayName,LastLogonDate,WhenCreated,DistinguishedName,Description,Enabled,PasswordLastSet,UserPrincipalName -ErrorAction Stop

    # Prepare output array
    $UserData = @()
    $UserCount = 0

    foreach ($User in $Users) {
        $UserData += [PSCustomObject]@{
            SamAccountName    = $User.SamAccountName
            DisplayName       = $User.DisplayName
            UserPrincipalName = $User.UserPrincipalName
            WhenCreated       = $User.WhenCreated.ToString("yyyy-MM-dd HH:mm:ss")
            LastLogonDate     = if ($User.LastLogonDate) { $User.LastLogonDate.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss") } else { "" }
            PasswordLastSet   = if ($User.PasswordLastSet) { $User.PasswordLastSet.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss") } else { "" }
            AccountStatus     = if ($User.Enabled) { "Enabled" } else { "Disabled" }
            OUPath            = Get-OUPath -DistinguishedName $User.DistinguishedName
            Action            = ""
            Description       = $User.Description
            InteractiveLogin  = ""  # No reliable way to determine this in standard AD attributes
        }
        $UserCount++
    }

    # Export to CSV
    try {
        $UserData | Export-Csv -Path $OutputCSV -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        Write-Log "Successfully exported $UserCount user records to $OutputCSV"
    }
    catch {
        Write-Log "Failed to export CSV: $($_.Exception.Message)"
        throw
    }

    # Output summary to console
    Write-Host "Audit completed. $UserCount users exported to $OutputCSV"
    Write-Host "Log file created at $LogFile"
}
catch {
    Write-Log "Error occurred: $($_.Exception.Message)"
    Write-Host "An error occurred. Check the log file at $LogFile for details." -ForegroundColor Red
    throw
}
finally {
    Write-Log "Script execution completed"
}
