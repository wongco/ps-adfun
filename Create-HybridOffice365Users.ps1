# Place supporting .csv file in same directory
$employees = import-csv BatchOffice365Users.csv

# -- Begin Local Exchange Session --
# Specify Credentials with permission to create exchange objects and access AD
# Example : $exchadmin = "wongco\exchDomainAdmin"
$exchadmin = "-----FILL IN------"
$exchcred = Get-Credential -Message "Domain Credentials are required for Create-HybridOffice365Users.ps1" -UserName $exchadmin
# Example : -ConnectionURI should be the PowerShell URI for your Local Exchange Server: http://exch.wongco.local/PowerShell/
$EXCHSESSION = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "-----FILL IN-----" -Authentication Kerberos -Credential $exchcred
Import-PSSession $EXCHSESSION

#Support Module for Create User in Local Exchange
Import-Module ActiveDirectory

# $ou example = 'wongco.local/Office365Users"
$ou = "<----Place desired OU here as destination container for new users---->"

#Create User in Local Exchange to Prep Propogation to Office365
foreach($staff in $employees){
    $firstname = $staff.FirstName
    $lastname = $staff.LastName
    $userupn = $staff.UPN
    $userpw = $staff.UserPW
    $desc = $staff.UserDesc
    
    # $alias - customize the next two fields as needed. by default assumes you want alias to match upn
    $alias = $userupn.Split("{@}")[0]
    $displayname = $firstname + ' ' + $lastname

    #Creates Local User and Provisions Office365 Mailbox
    # Note: Creates new user using plainstring password. User will need to change immediately upon login to ensure security
    New-RemoteMailbox -UserPrincipalName $userupn -Alias $alias -Name $displayname -FirstName $firstname -LastName $lastname -DisplayName $displayname -OnPremisesOrganizationalUnit $ou -Password (ConvertTo-SecureString $userpw -AsPlainText -Force) -ResetPasswordOnNextLogon $true
}

Remove-PSSession $EXCHSESSION
#End Exch Session

Write-Host "Setting script to go to sleep for 1 minute to wait on completion of AD Propogation"
#1 Minutes Script Sleep
Start-Sleep -s (60)

#Set User Descriptions in AD
foreach($staff in $employees){
    $firstname = $staff.FirstName
    $lastname = $staff.LastName
    $userupn = $staff.UPN
    $userpw = $staff.UserPW
    $desc = $staff.UserDesc

    # $alias - customize the next two fields as needed. by default assumes you want alias to match upn
    $alias = $userupn.Split("{@}")[0]
    $displayname = $firstname + ' ' + $lastname
    
    #Set User Description
    $aduser = Get-ADUser -Identity $alias -Credential $localcred
    Set-ADUser $aduser.sAMAccountName -Description $desc -Credential $localcred
}

#Connect to Domain Controller w/(AADConnect) ADSync Installed and Force Delta Sync - Propogate to Office365
$AADSESSION = New-PSSession -ComputerName AAD -Credential $exchcred
Invoke-Command -Session $AADSESSION -ScriptBlock {Import-Module ADSync}
Invoke-Command -Session $AADSESSION -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Delta}
Remove-PSSession $AADSESSION

#Create Time Delay for Sync Completion
Write-Host "Setting script to go to sleep for 5 minutes to wait on completion of ADSync Delta"
#5 Minutes Script Sleep
Start-Sleep -s (60*5)

<#
.SYNOPSIS
This is a Powershell batch file to create Office365-AD Enabled Users in an Hybrid Environment

.DESCRIPTION
Requirement: BatchOffice365Users.csv must be properly filled out. This file is designed to execute all steps required to create a new user account

.EXAMPLE
Create-HybridOffice365Users.ps1

.NOTES
Updated 2018-09-13
#>