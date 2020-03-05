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
$log = "c:\temp\psft-pi-baker.log"

#-----------------------------------------------------------[Functions]-----------------------------------------------------------
Function log($msg) {
    $stamp = [DateTime]::Now.ToString("yyyyMMdd-HHmmss")
    Add-Content $log "[$stamp] $msg"
}
Function info($msg) {
    log("INFO: $msg")
}
Function debug($msg) {
    log("DEBUG: $msg")
}
Function error($msg) {
    log("ERROR: $msg")
}

#-----------------------------------------------------------[Execution]-----------------------------------------------------------
# testing log
info("Testing info")
debug("Testing debug")
error("Testing error")

# Setup file structure
info("Setting up file structure...")
New-Item -ItemType directory -Path "c:/psft/dpk/downloads"
New-Item -ItemType directory -Path "c:/vagrant/config"
New-Item -ItemType directory -Path "c:/vagrant/scripts"
Copy-Item -Path "./files/psft_customizations-win.yaml" -Destination "c:/vagrant/config/psft_customizations.yaml" 
Copy-Item -Path "./files/vagabond.json" -Destination "c:/vagrant/scripts/vagabond.json" 
info("...done.")

# Run provisoners
info("banner")
& ./powershell/banner.ps1 > $log
info("downnload")
& ./powershell/provision-download.ps1 -MOS_USERNAME "$MOS_USERNAME" -MOS_PASSWORD "$MOS_PASSWORD" -PATCH_ID "$MOS_PATCH_ID" -DPK_INSTALL "c:/psft/dpk/downloads/$MOS_PATCH_ID" > $log
info("bootstrap")
& ./powershell/provision-bootstrap-ps.ps1 -PATCH_ID "${MOS_PATCH_ID}" -DPK_INSTALL "c:/psft/dpk/downloads/${MOS_PATCH_ID}" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet" > $log
info("yaml")
& ./powershell/provision-yaml.ps1 -DPK_INSTALL "c:/psft/dpk/downloads/${MOS_PATCH_ID}" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet" > $log
info("puppet apply")
& ./powershell/provision-puppet-apply.ps1 -DPK_INSTALL "c:/psft/dpk/downloads/${MOS_PATCH_ID}" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet" > $log
info("util")
& ./powershell/provision-puppet-utilities.ps1 > $log

info("done done.")
