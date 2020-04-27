#Requires -Version 5

<#PSScriptInfo

    .VERSION 1.0

    .GUID cad7db76-01e8-4abd-bdb9-3fca50cadbc7

    .AUTHOR psadmin.io

    .SYNOPSIS
        ps-vagabond provisioning utilitis

    .DESCRIPTION
        Provisioning script for ps-vagabond to install various utilities

    .EXAMPLE
        provision-utilities.ps1 
#>

#-----------------------------------------------------------[Parameters]----------------------------------------------------------

[CmdletBinding()]
Param(
)


#---------------------------------------------------------[Initialization]--------------------------------------------------------

# Valid values: "Stop", "Inquire", "Continue", "Suspend", "SilentlyContinue"
$ErrorActionPreference = "Stop"
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#-----------------------------------------------------------[Variables]-----------------------------------------------------------


#-----------------------------------------------------------[Functions]-----------------------------------------------------------

function install_psadmin_plus() {
  # Fix Ruby Gems CA
  # https://gist.github.com/iversond/772e73257c4ca59a9e6137baa7288788
  $CACertFile = Join-Path -Path $ENV:AppData -ChildPath 'RubyCACert.pem'

  If (-Not (Test-Path -Path $CACertFile)) {  
    #"Downloading CA Cert bundle.."
    Invoke-WebRequest -Uri 'https://curl.haxx.se/ca/cacert.pem' -UseBasicParsing -OutFile $CACertFile | Out-Null
  }

  # "Setting CA Certificate store set to $CACertFile.."
  $ENV:SSL_CERT_FILE = $CACertFile
  [System.Environment]::SetEnvironmentVariable('SSL_CERT_FILE',$CACertFile, [System.EnvironmentVariableTarget]::Machine)

  gem install psadmin_plus
  gem install mosbot
  [System.Environment]::SetEnvironmentVariable('PATH',"${env:PATH};C:\Program Files\Puppet Labs\Puppet\sys\ruby\bin", [System.EnvironmentVariableTarget]::Machine)
  
}

function install_browsers() {
  Write-Output "[${env:COMPUTERNAME}] Installing Browsers"
  choco install googlechrome -y
	choco install firefox -y
}

function install_code_management() {
  Write-Output "[${env:COMPUTERNAME}] Installing Code Management Software"
  choco install VSCode -y
  [System.Environment]::SetEnvironmentVariable('PATH',"${env:PATH};C:\Program Files\Microsoft VS Code\bin", [System.EnvironmentVariableTarget]::Machine)
  
  choco install git -y
  [System.Environment]::SetEnvironmentVariable('PATH',"${env:PATH};C:\Program Files\Git\bin", [System.EnvironmentVariableTarget]::Machine)
}

function install_command_line_utils() {
  Write-Output "[${env:COMPUTERNAME}] Installing Command Line Utilities"
  choco install grep -y
  choco install 7zip -y
  choco install nssm -y
  iwr https://github.com/MarisElsins/getMOSPatch/raw/master/getMOSPatch.jar -outfile c:\temp\getMOSPatch.jar
}

function fix_puppet_path() {
  Write-Output "[${env:COMPUTERNAME}] Fix PATH"
  [System.Environment]::SetEnvironmentVariable('PATH',"${env:PATH};C:\Program Files\Puppet Labs\Puppet\bin", [System.EnvironmentVariableTarget]::Machine)
}

function start_tuxedo_domains() {
  Write-Output "[${env:COMPUTERNAME}] Start Tuxedo Domains"

}

#-----------------------------------------------------------[Execution]-----------------------------------------------------------


. install_browsers
. install_code_management
. install_psadmin_plus
. install_command_line_utils
. fix_puppet_path