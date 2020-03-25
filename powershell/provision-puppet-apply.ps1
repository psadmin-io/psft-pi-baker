#Requires -Version 5

<#PSScriptInfo

    .VERSION 1.0

    .GUID cad7db76-01e8-4abd-bdb9-3fca50cadbc7

    .AUTHOR psadmin.io

    .SYNOPSIS
        ps-vagabond provisioning puppet

    .DESCRIPTION
        Provisioning script for ps-vagabond to copy custom yaml and run puppet apply

    .PARAMETER PUPPET_HOME
        Puppet home directory

    .EXAMPLE
        provision-puppet.ps1 -PUPPET_HOME C:\ProgramData\PuppetLabs\puppet\etc -PT_VERSION 856

#>

#-----------------------------------------------------------[Parameters]----------------------------------------------------------

[CmdletBinding()]
Param(
  [String]$DPK_INSTALL      = $env:DPK_INSTALL,
  [String]$PSFT_BASE_DIR    = $env:PSFT_BASE_DIR,
  [String]$PUPPET_HOME      = $env:PUPPET_HOME
)


#---------------------------------------------------------[Initialization]--------------------------------------------------------

# Valid values: "Stop", "Inquire", "Continue", "Suspend", "SilentlyContinue"
$ErrorActionPreference = "Stop"
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"

#------------------------------------------------------------[Variables]----------------------------------------------------------

$DEBUG = "true"

#-----------------------------------------------------------[Functions]-----------------------------------------------------------


function determine_tools_version() {
  $TOOLS_VERSION = $(Get-Content ${DPK_INSTALL}/setup/bs-manifest | select-string "version" | % {$_.line.split("=")[1]})
  $TOOLS_MAJOR_VERSION = $TOOLS_VERSION.split(".")[0]
  $TOOLS_MINOR_VERSION = $TOOLS_VERSION.split(".")[1]
  $TOOLS_PATCH_VERSION = $TOOLS_VERSION.split(".")[2]

  if ($DEBUG -eq "true") {
      Write-Output "Tools Version: ${TOOLS_VERSION}"
      Write-Output "Tools Major Version: ${TOOLS_MAJOR_VERSION}"
      Write-Output "Tools Minor Version: ${TOOLS_MINOR_VERSION}"
      Write-Output "Tools Patch Version: ${TOOLS_PATCH_VERSION}"
  }
}

function determine_puppet_home() {
  switch ($TOOLS_MINOR_VERSION) {
      "55" { 
        $PUPPET_HOME = "C:\ProgramData\PuppetLabs\puppet\etc"
      }
      "56" {
        $PUPPET_HOME = "${PSFT_BASE_DIR}/dpk/puppet"
      }
      "57" {
        $PUPPET_HOME = "${PSFT_BASE_DIR}/dpk/puppet"
      }
      "58" {
        $PUPPET_HOME = "${PSFT_BASE_DIR}/dpk/puppet"
      }
      Default { Write-Output "PeopleTools version could not be determined in the bs-manifest file."}
  }  

  if ($DEBUG -eq "true" ) {
      Write-Output "Tools Minor Version: ${TOOLS_MINOR_VERSION}"
      Write-Output "Puppet Home Directory: ${PUPPET_HOME}"
  }
}

function execute_puppet_apply() {
  Write-Output "Applying Puppet manifests"
  # Reset Environment and PATH to include bin\puppet
  $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

  switch ($TOOLS_MINOR_VERSION) {
    "58" {
      if ($DEBUG -eq "true") {
        . refreshenv
        puppet apply "${PUPPET_HOME}\production\manifests\site.pp" --confdir="${PUPPET_HOME}" --trace --debug
      } else {
        . refreshenv | out-null
        puppet apply "${PUPPET_HOME}\production\manifests\site.pp" 2>&1 | out-null
      }
    }"57" {
      if ($DEBUG -eq "true") {
        . refreshenv
        puppet apply "${PUPPET_HOME}\production\manifests\site.pp" --confdir="${PUPPET_HOME}" --trace --debug
      } else {
        . refreshenv | out-null
        puppet apply "${PUPPET_HOME}\production\manifests\site.pp" 2>&1 | out-null
      }
    }
    "56" {
      if ($DEBUG -eq "true") {
        . refreshenv
        puppet apply "${PUPPET_HOME}\production\manifests\site.pp" --confdir="${PUPPET_HOME}" --trace --debug
      } else {
        . refreshenv | out-null
        puppet apply "${PUPPET_HOME}\production\manifests\site.pp" 2>&1 | out-null
      }
    }
    "55" {
      if ($DEBUG -eq "true") {
        . refreshenv
        puppet apply "${PUPPET_HOME}\manifests\site.pp" --trace --debug
      } else {
        . refreshenv | out-null
        puppet apply "${PUPPET_HOME}\manifests\site.pp" 2>&1 | out-null
      }
    }
  } # end switch
}

function prebuild_cache() {
  Write-Output "Prebuilding Application Cache"
  # Reset Environment and PATH to include bin\puppet
  $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

  switch ($TOOLS_MINOR_VERSION) {
    "55" {
      write-output "8.55 DPK not supported for preloading cache"
    }
    "56" {
      execute_prebuild_cache
    }
    "57" {
      execute_prebuild_cache
    }
    "58" {
      execute_prebuild_cache
    }
  } # end switch
}

function execute_prebuild_cache() {
  if ($DEBUG -eq "true") {
    puppet module install puppetlabs-powershell --confdir ${PUPPET_HOME}
    invoke-webrequest -method GET -uri https://gist.githubusercontent.com/iversond/60f0e820bc476f16d5d6b2161fbbafbb/raw/fixdpkbug.pp -outfile "c:\temp\fixdpkbug.pp"
    invoke-webrequest -method GET -uri https://gist.githubusercontent.com/iversond/48af2c095c883277fe08f85d415739b1/raw/loadcache.pp -outfile "c:\temp\loadcache.pp"
    puppet apply c:\temp\fixdpkbug.pp --confdir="${PUPPET_HOME}"
    puppet apply c:\temp\loadcache.pp --confdir="${PUPPET_HOME}"
  } else {
    puppet module install puppetlabs-powershell --confdir ${PUPPET_HOME} 2>&1 | out-null
    invoke-webrequest -method GET -uri https://gist.githubusercontent.com/iversond/60f0e820bc476f16d5d6b2161fbbafbb/raw/fixdpkbug.pp -outfile "c:\temp\fixdpkbug.pp" 2>&1 | out-null
    invoke-webrequest -method GET -uri https://gist.githubusercontent.com/iversond/48af2c095c883277fe08f85d415739b1/raw/loadcache.pp -outfile "c:\temp\loadcache.pp" 2>&1 | out-null
    puppet apply c:\temp\fixdpkbug.pp --confdir="${PUPPET_HOME}" 2>&1 | out-null
    puppet apply c:\temp\loadcache.pp --confdir="${PUPPET_HOME}" 2>&1 | out-null
  }
}

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

. determine_tools_version
. determine_puppet_home
. execute_puppet_apply
. prebuild_cache