#Requires -Version 5
<#PSScriptInfo
    .VERSION 1.0
    .GUID TODO
    .AUTHOR psadmin.io
    .SYNOPSIS
        todo
    .DESCRIPTION
        todo
    .EXAMPLE
        provision-utilities.ps1 
#>
#-----------------------------------------------------------[Parameters]----------------------------------------------------------
[CmdletBinding()]
Param(
    [String]$MOS_USERNAME = $env:MOS_USERNAME,
    [String]$MOS_PASSWORD = $env:MOS_PASSWORD,
    [String]$MOS_PATCH_ID = $env:MOS_PATCH_ID
)
#---------------------------------------------------------[Initialization]--------------------------------------------------------
# Valid values: "Stop", "Inquire", "Continue", "Suspend", "SilentlyContinue"
$ErrorActionPreference = "Stop"
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"

#-----------------------------------------------------------[Variables]-----------------------------------------------------------

#-----------------------------------------------------------[Functions]-----------------------------------------------------------

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

New-Item -ItemType directory -Path "c:/psft/dpk/downloads"
New-Item -ItemType directory -Path "c:/vagrant/config"
New-Item -ItemType directory -Path "c:/vagrant/scripts"
Copy-Item -Path "./config/psft_customizations-win.yaml" -Destination "c:/vagrant/config/psft_customizations.yaml" 
Copy-Item -Path "./config/vagabond.json" -Destination "c:/vagrant/scripts/vagabond.json" 

& ./powershell/banner.ps1
& ./powershell/provision-download.ps1 -MOS_USERNAME "$MOS_USERNAME" -MOS_PASSWORD "$MOS_PASSWORD" -PATCH_ID "$MOS_PATCH_ID" -DPK_INSTALL "c:/psft/dpk/downloads/$MOS_PATCH_ID"
& ./powershell/provision-bootstrap-ps.ps1 -PATCH_ID "${MOS_PATCH_ID}" -DPK_INSTALL "c:/psft/dpk/downloads/${MOS_PATCH_ID}" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet"
& ./powershell/provision-yaml.ps1 -DPK_INSTALL "c:/psft/dpk/downloads/${MOS_PATCH_ID}" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet"
& ./powershell/provision-puppet-apply.ps1 -DPK_INSTALL "c:/psft/dpk/downloads/${MOS_PATCH_ID}" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet"
& ./powershell/provision-puppet-utilities.ps1
