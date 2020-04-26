#Requires -Version 5

<#PSScriptInfo

    .VERSION 1.0

    .GUID cad7db76-01e8-4abd-bdb9-3fca50cadbc7

    .AUTHOR psadmin.io

    .SYNOPSIS
        ps-vagabond ELK provisioning

    .DESCRIPTION
        ELK provisioning bootstrap script for ps-vagabond

    .PARAMETER ELK_INSTALL
        Directory to use for downloading the ELK file
    .PARAMETER APP
        Application Type: FSCM92, HCM92, ELM92, IH92, CS92
    .PARAMETER PUPPET_HOME
        Puppet Home for the DPK
    .PARAMETER ESADMIN_PWD
        Password to encrypt for esadmin
    .PARAMETER PEOPLE_PWD
        Password to encrypt for people
    .PARAMETER ELK_BASE_DIR
        Installation location for ELK

    .EXAMPLE
        provision-elk.ps1 -ELK_INSTALL C:/peoplesoft/dpk/download/elk7

#>

#-----------------------------------------------------------[Parameters]----------------------------------------------------------

[CmdletBinding()]
Param(
  [String]$ELK_INSTALL  = $env:ELK_INSTALL,
  [String]$APP          = $env:APP,
  [String]$ESADMIN_PWD  = $env:ESADMIN_PWD,
  [String]$PEOPLE_PWD   = $env:PEOPLE_PWD,
  [String]$PUPPET_HOME  = $env:PUPPET_HOME,
  [String]$ELK_BASE_DIR = $env:ELK_BASE_DIR
)


#---------------------------------------------------------[Initialization]--------------------------------------------------------

# Valid values: "Stop", "Inquire", "Continue", "Suspend", "SilentlyContinue"
$ErrorActionPreference = "Stop"
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"

#------------------------------------------------------------[Variables]----------------------------------------------------------

If ( ${ELK_INSTALL} -eq '' ) { Write-Output "ELK_INSTALL must be passed" }

$DEBUG = "true"

function determine_elk_version() {
    $ELK_VERSION = $(Get-Content ${ELK_INSTALL}/elasticsearch-manifest | select-string "^version" | % {$_.line.split("=")[1]})
    $ELK_MAJOR_VERSION = $ELK_VERSION.split(".")[0]
    $ELK_MINOR_VERSION = $ELK_VERSION.split(".")[1]
    $ELK_PATCH_VERSION = $ELK_VERSION.split(".")[2]

    if ($DEBUG -eq "true") {
        Write-Output "ELK Version: ${ELK_VERSION}"
        Write-Output "  Major Version: ${ELK_MAJOR_VERSION}"
        Write-Output "  Minor Version: ${ELK_MINOR_VERSION}"
        Write-Output "  Patch Version: ${ELK_PATCH_VERSION}"
    }
}

function encrypt_es_passwords() {
    Write-Output "Encrypting Elasticsearch passwords"

    # Extract Elasticsearch pscipher and psvault to use for encryption
    7z x $ELK_INSTALL\archives\pt-elasticsearch-$ELK_VERSION.tgz -o"$env:TEMP\es\" 2>&1 | out-null
    7z e $env:TEMP\es\pt-elasticsearch-$ELK_VERSION.tgz -o"$env:TEMP\es\" psvault -r -aoa 2>&1 | out-null
    7z e $env:TEMP\es\pt-elasticsearch-$ELK_VERSION.tgz -o"$env:TEMP\es\" pscipher.jar -r -aoa 2>&1 | out-null

    # Encrypt passwords for Elasticsearch
    $PSCIPHER_PATH="${env:TEMP}\es"
    $PSCIPHER="${PSCIPHER_PATH}\pscipher.jar"
    $JAR_LIB="com.peoplesoft.pt.elasticsearch.pscipher.PSESEncrypt"
    cmd /c "java -Dpscipher.path=${PSCIPHER_PATH} -cp ${PSCIPHER} ${JAR_LIB} esadmin ${ESADMIN_PWD} people ${PEOPLE_PWD} es_password.txt"
    
    $esadmin_pass_es = $(gc es_password.txt | select-string esadmin | % {$_.line.split(":")[1]})
    $people_pass_es = $(gc es_password.txt | select-string people | % {$_.line.split(":")[1]})

    # Cleanup temp files
    Remove-Item $env:TEMP\es -recurse
    Remove-Item es_password.txt
}

function encrypt_ls_passwords() {
    Write-Output "Encrypting Logstash passwords"

    # Extract Logstash pscipher and psvault to use for encryption
    7z x $ELK_INSTALL\archives\pt-logstash-$ELK_VERSION.tgz -o"$env:TEMP\ls\" 2>&1 | out-null
    7z x $env:TEMP\ls\pt-logstash-$ELK_VERSION.tgz -o"$env:TEMP\ls\" 2>&1 | out-null
    
    # Encrypt Passwords for Logstash
    $LOGSTASH_HOME="$env:TEMP\ls"
    $esadmin_pass_ls = (cmd /c  ${LOGSTASH_HOME}\pt\bin\pslscipher.bat ${ESADMIN_PWD}).split(" ")[2]
    $people_pass_ls = (cmd /c  ${LOGSTASH_HOME}\pt\bin\pslscipher.bat ${PEOPLE_PWD}).split(" ")[2]
    $ib_user = (cmd /c  ${LOGSTASH_HOME}\pt\bin\pslscipher.bat ${db_user}).split(" ")[2]
    $ib_pass = (cmd /c  ${LOGSTASH_HOME}\pt\bin\pslscipher.bat ${db_user_pwd}).split(" ")[2]

    # Cleanup temp files
    Remove-Item $env:TEMP\ls -recurse
}

function generate_response_file() {
    $file = New-Item -type file "${ELK_INSTALL}/setup/silentinstall.config" -force

    $hostname = $(facter hostname)
    $domain = $(facter domain)
    $piahttpport = $(hiera pia_http_port -c $PUPPET_HOME\hiera.yaml)
    $db_user = $(hiera db_user -c $PUPPET_HOME\hiera.yaml)
    $db_user_pwd = $(hiera db_user_pwd -c $PUPPET_HOME\hiera.yaml)
    
    . encrypt_es_passwords
    . encrypt_ls_passwords

    switch ($APP) {
        "FSCM92" {
            $nodename = "PSFT_EP"
        }
    }

    $template=@"
Install elasticsearch?[Y/N]= y
cluster.name= ESCLUSTER
network.host= localhost
esadmin.password= ${esadmin_pass_es}
people.password= ${people_pass_es}
http.port=9200
path.data= $ES_HOME/data
path.logs= $ES_HOME/logs
discovery.hosts= ["127.0.0.1", "[::1]"]
minimum_master_nodes= 1
ES_HEAP_SIZE=2
Install Logstash(for PHC)?[Y/N]= y
IB_REST_URL= http://${hostname}.${domain}:${piahttpport}/PSIGW/RESTListeningConnector/${nodename}/PT_CREATEJSON_REST.v1/json=
IB_USER= ${ib_user}
IB_PWD= ${ib_pass}
JSON_LOC=${ELK_BASE_DIR}/pt/Logstash${ELK_VERSION}/pt/jmxmonitor 
polling_freq = 60
no_of_threads = 2
ES_host = ${hostname}.${domain}
ES_port = 9200
ES_user = esadmin
#The encrypted Elasticsearch password [encrypted using PSLSCipher.bat/PSLSCipher.sh] (mandatory)
ES_pwd = ${esadmin_pass_ls}
JSON_files?[Y/N] = y
Install kibana?[Y/N]= y
kibana.host= ${hostname}.${domain}
kibana.port=5601
Use same ES?[Y/N]= y
Upgrade elasticsearch?[Y/N]= n
"@ 

    if ($DEBUG -eq "true") {
        Write-Output "Response File Template: ${template}"
        Write-Output "Writing to location: ${file}"
    }
    $template | out-file $file -Encoding ascii
}
function execute_psft_dpk_setup() {

  Write-Output "Executing ELK setup script"
  Write-Output "ELK INSTALL: ${ELK_INSTALL}"

  switch ($ELK_MAJOR_VERSION) {
    "7" {
        Write-Output "ELK Version 7"
        set-location $ELK_INSTALL\setup

        if ($DEBUG -eq "true") {
            . "${ELK_INSTALL}/setup/psft-dpk-setup.bat" `
            --install_silent `
            --install_base_dir "${ELK_BASE_DIR}" `
            --config_file "${ELK_INSTALL}/setup/silentinstall.config" 
        } else {
            . "${ELK_INSTALL}/setup/psft-dpk-setup.bat" `
            --install_silent `
            --install_base_dir "${ELK_BASE_DIR}" `
            --config_file "${ELK_INSTALL}/setup/silentinstall.config" 2>&1 | out-null
        }
    } 
    default { Write-Output "ELK Version not supported yet"}
  }
}

function create_services() {
    
    # Elasticsearch
    nssm set elasticsearch-service-x64 Start SERVICE_AUTO_START
    
    # Kiabna
    nssm install kibana ${ELK_BASE_DIR}\pt\Kibana${ELK_VERSION}\bin\kibana.bat 
    nssm set kibana AppDirectory ${ELK_BASE_DIR}\pt\Kibana${ELK_VERSION}\bin
    nssm set kibana Start SERVICE_AUTO_START 
    nssm set kibana Description "Kibana ${ELK_VERSION}"
    start-service kibana

    # Logstash
    nssm install logstash "${ELK_BASE_DIR}\pt\Logstash${ELK_VERSION}\bin\logstash.bat"
    nssm set logstash AppParameters "-f ${ELK_BASE_DIR}\pt\Logstash${ELK_VERSION}\pt\config\LogstashPipeLine.CONF"
    nssm set logstash AppDirectory ${ELK_BASE_DIR}\pt\Logstash${ELK_VERSION}\bin
    nssm set logstash Start SERVICE_AUTO_START 
    nssm set logstash Description "Logstash ${ELK_VERSION}"
    nssm set logstash AppEnvironmentExtra LOGSTASH_HOME=${ELK_BASE_DIR}\pt\Logstash${ELK_VERSION}
    start-service logstash
    
}

$start_loc = $(get-location)

. determine_elk_version
. generate_response_file
. execute_psft_dpk_setup
. create_services

set-location $start_loc