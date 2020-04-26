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
       TODO
#>

[CmdletBinding(DefaultParameterSetName="Help")]

Param(
    [Parameter(Mandatory=$true)][String]$MOS_USERNAME       = $env:MOS_USERNAME,
    [Parameter(Mandatory=$true)][String]$MOS_PASSWORD       = $env:MOS_PASSWORD, # TODO secure string
    [Parameter(Mandatory=$true)][String]$MOS_PATCH_ID       = $env:MOS_PATCH_ID,
    [Parameter(Mandatory=$false)][String]$MOS_ELK_PATCH_ID  = $env:MOS_ELK_PATCH_ID
)

Begin {
    # TODO - params?
    # Valid values: "Stop", "Inquire", "Continue", "Suspend", "SilentlyContinue"
    $ErrorActionPreference = "Stop"
    $DebugPreference = "SilentlyContinue"
    $VerbosePreference = "SilentlyContinue"

    $log = "c:\temp\psft-pi-baker.log" # TODO

    Push-Location $PSScriptRoot

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
}

Process {
    # Setup file structure
    Try {        
        info("Setting up file structure.")        
        New-Item -ItemType directory -Path "c:/psft/cfg" -Force
        New-Item -ItemType directory -Path "c:/psft/dpk/downloads" -Force
        New-Item -ItemType directory -Path "c:/vagrant/config" -Force
        New-Item -ItemType directory -Path "c:/vagrant/scripts" -Force
        Copy-Item -Path "./files/psft_customizations-win.yaml" -Destination "c:/vagrant/config/psft_customizations.yaml" 
        Copy-Item -Path "./files/vagabond.json" -Destination "c:/vagrant/scripts/vagabond.json" 
    } Catch {
        error($_.Exception.Message)
        Break
    }

    # Run provisoners
    info("banner")
    & ./powershell/banner.ps1 >> $log
    info("download")
    & ./powershell/provision-download.ps1 -MOS_USERNAME "$MOS_USERNAME" -MOS_PASSWORD "$MOS_PASSWORD" -PATCH_ID "$MOS_PATCH_ID" -DPK_INSTALL "c:/psft/dpk/downloads/$MOS_PATCH_ID" >> $log
    info("bootstrap")
    & ./powershell/provision-bootstrap-ps.ps1 -PATCH_ID "$MOS_PATCH_ID" -DPK_INSTALL "c:/psft/dpk/downloads/$MOS_PATCH_ID" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet" >> $log
    info("yaml")
    & ./powershell/provision-yaml.ps1 -DPK_INSTALL "c:/psft/dpk/downloads/$MOS_PATCH_ID" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet" >> $log
    info("puppet apply")
    & ./powershell/provision-puppet-apply.ps1 -DPK_INSTALL "c:/psft/dpk/downloads/$MOS_PATCH_ID" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet" >> $log
    info("util")
    & ./powershell/provision-utilities.ps1 >> $log

    if (${MOS_ELK_PATCH_ID}) {
        & ./powershell/provision-download.ps1 -MOS_USERNAME "${MOS_USERNAME}" -MOS_PASSWORD "${MOS_PASSWORD}" -PATCH_ID "${MOS_ELK_PATCH_ID}" -DPK_INSTALL "c:/psft/dpk/downloads/${MOS_ELK_PATCH_ID}" | set-content -path $log

        $APP = (ls c:/psft/dpk/downloads/${MOS_PATCH_ID}\APP*.zip | select -First 1).Name.split("-")[3]
        & ./powershell/provision-elk.ps1 -ELK_INSTALL "c:/psft/dpk/downloads/${MOS_ELK_PATCH_ID}" -APP $APP -PUPPET_HOME "c:/psft/dpk/puppet" -ELK_BASE_DIR "c:/psft/elk" -ESADMIN_PWD "Passw0rd#" -PEOPLE_PWD "peop1e" | set-content -path $log
    }


    info("done done.")
}

End {
    Pop-Location
}