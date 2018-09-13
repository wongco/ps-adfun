#Support Module for AD Quries
Import-Module ActiveDirectory

#OU conatining Computers needing to be added to AD Group
#Example $OU = "OU=Laptops,DC=wongco,DC=local"
$OU = #Specify OU ----------FILL THIS LINE IN-------------

#Specifies target Security Group
#Example $ShadowGroup = "CN=Level1AccessLaptops,OU=Security Groups,DC=wongco,DC=local"
$ShadowGroup = #Specify Distribution Group ----------FILL THIS LINE IN-------------

#Check computers currently in Security Group & Remove Old Members
Get-ADGroupMember –Identity $ShadowGroup | Where-Object {$_.distinguishedName –NotMatch $OU} | ForEach-Object {Remove-ADPrincipalGroupMembership –Identity $_ –MemberOf $ShadowGroup –Confirm:$false}

#Check computers currently in OU but not in Security Group & Add
Get-ADComputer –SearchBase $OU –SearchScope OneLevel –LDAPFilter "(!memberOf=$ShadowGroup)" | ForEach-Object {Add-ADPrincipalGroupMembership –Identity $_ –MemberOf $ShadowGroup}

<#

.SYNOPSIS
This is a Powershell Script to maintain a relationship between an OU container of computers and an AD Security Group. You can run dsquery to find the base DN/OU of the groups you are specifying. Script Needs $OU & $ShadowGroup to be filled out before running.

.DESCRIPTION
This script can be placed on a member server with appropriate permissions using Task Scheduler and scripted to run every hour to syncronize group membership.

.EXAMPLE
Add-ComputerOUToSecurityGroup.ps1

.NOTES
Credits: Original script from https://ravingroo.com/458/active-directory-shadow-group-automatically-add-ou-users-membership/
Changes from Original Script: Customized to accomodate Computers instead of Users & Added comments to script for usability and clarity

Updated 2018-09-13
#>