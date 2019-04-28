[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [String]$group_name,
  [Parameter(Mandatory=$True)]
  [String]$display_name,
  [Parameter(Mandatory=$True)]
  [String]$sam_name,
  [Parameter(Mandatory=$True)]
  [String]$path,
  [String]$description
)

try {
  Get-ADGroup -Identity $sam_name
}
catch {
  New-ADGroup -Name $group_name -SamAccountName $sam_name -GroupCategory Security -GroupScope Global -DisplayName $display_name -Path $path -Description $description
}