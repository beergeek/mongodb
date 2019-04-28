[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [String]$name,
  [Parameter(Mandatory=$True)]
  [String]$password,
  [Parameter(Mandatory=$True)]
  [String]$given_name = $name,
  [Parameter(Mandatory=$True)]
  [String]$path,,
  [Parameter(Mandatory=$True)],
  [Boolean]$password_never_expires = $False,
  [Parameter(Mandatory=$True)],
  [Boolean]$change_password_at_logon = $False,
  [Parameter(Mandatory=$True)],
  [Boolean]$cannot_change_password = $False,
  [String[]]$groups,
  [String]$kerberos_encryption,
)

$secureString = ConvertTo-SecureString $password -AsPlainText -Force

New-ADUser -Name $name -AccountPassword $secureString -GivenName $given_name -Enabled $True -Path $path -PasswordNeverExpires $password_never_expires -ChangePasswordAtLogon $change_password_at_logon -CannotChangePassword $cannot_change_password -KerberosEncryptionType $kerberos_encryption