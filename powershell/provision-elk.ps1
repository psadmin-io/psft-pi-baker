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

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls13, [Net.SecurityProtocolType]::Tls12 

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

function configure_java() {
    $JRE_VERSION = $(Get-Content ${ELK_INSTALL}/elasticsearch-manifest | select-string jre_version | % { $_.line.split("=")[1].split(" ")[0] })
    $JAVA_HOME="${env:TEMP}\jre"
    7z x $ELK_INSTALL\archives\pt-jre$JRE_VERSION.tgz -o"$JAVA_HOME" 2>&1 | out-null
    7z x $JAVA_HOME\pt-jre$JRE_VERSION.tgz -o"$JAVA_HOME" 2>&1 | out-null
    $env:JAVA_HOME="${JAVA_HOME}"
    $env:PATH="${env:PATH};${JAVA_HOME}\bin"
}

function encrypt_es_passwords() {
    Write-Output "Encrypting Elasticsearch passwords"

    $ELASTIC_HOME="${env:TEMP}\es"
    # Extract Elasticsearch pscipher and psvault to use for encryption
    7z x $ELK_INSTALL\archives\pt-elasticsearch-$ELK_VERSION.tgz -o"$ELASTIC_HOME\" 2>&1 | out-null
    7z e $ELASTIC_HOME\pt-elasticsearch-$ELK_VERSION.tgz -o"$ELASTIC_HOME\" psvault -r -aoa 2>&1 | out-null
    7z e $ELASTIC_HOME\pt-elasticsearch-$ELK_VERSION.tgz -o"$ELASTIC_HOME\" pscipher.jar -r -aoa 2>&1 | out-null

    # Encrypt passwords for Elasticsearch
    $PSCIPHER_PATH="${env:TEMP}\es"
    $PSCIPHER="${PSCIPHER_PATH}\pscipher.jar"
    $JAR_LIB="com.peoplesoft.pt.elasticsearch.pscipher.PSESEncrypt"
    cmd /c "java -Dpscipher.path=${PSCIPHER_PATH} -cp ${PSCIPHER} ${JAR_LIB} esadmin ${ESADMIN_PWD} people ${PEOPLE_PWD} es_password.txt"
    
    $esadmin_pass_es = $(gc es_password.txt | select-string esadmin | % {$_.line.split(":")[1]})
    $people_pass_es = $(gc es_password.txt | select-string people | % {$_.line.split(":")[1]})

}

function encrypt_ls_passwords() {
    Write-Output "Encrypting Logstash passwords"

    $LOGSTASH_HOME="$env:TEMP\ls"
    # Extract Logstash pscipher and psvault to use for encryption
    7z x $ELK_INSTALL\archives\pt-logstash-$ELK_VERSION.tgz -o"$LOGSTASH_HOME" 2>&1 | out-null
    7z e $LOGSTASH_HOME\pt-logstash-$ELK_VERSION.tgz -o"$LOGSTASH_HOME" psvault -r -aoa 2>&1 | out-null
    7z e $LOGSTASH_HOME\pt-logstash-$ELK_VERSION.tgz -o"$LOGSTASH_HOME" psmanagement.jar -r -aoa 2>&1 | out-null
    7z e $LOGSTASH_HOME\pt-logstash-$ELK_VERSION.tgz -o"$LOGSTASH_HOME" pscipher.jar -r -aoa 2>&1 | out-null
    
    # Encrypt Passwords for Logstash
    # pslscipher.bat was failing - running the command directly and without extracting all of LOGSTASH_HOME
    $PSCIPHER_CMD="java -Dps_vault=${LOGSTASH_HOME}\psvault -cp ${LOGSTASH_HOME}\psmanagement.jar;${LOGSTASH_HOME}\pscipher.jar;${LOGSTASH_HOME} -DPROP_FILE=${LOGSTASH_HOME}\JsonLogstash.properties  psft.pt8.pshttp.PSCipher"
    $esadmin_pass_ls = (cmd /c "${PSCIPHER_CMD} ${ESADMIN_PWD}").split(" ")[2]
    $people_pass_ls  = (cmd /c "${PSCIPHER_CMD} ${PEOPLE_PWD}").split(" ")[2]
    $ib_user         = (cmd /c "${PSCIPHER_CMD} ${db_user}").split(" ")[2]
    $ib_pass         = (cmd /c "${PSCIPHER_CMD} ${db_user_pwd}").split(" ")[2]

}

function generate_response_file() {
    $file = New-Item -type file "${ELK_INSTALL}/setup/silentinstall.config" -force

    $hostname = $(facter hostname)
    $domain = $(facter domain)
    $piahttpport = $(hiera pia_http_port -c $PUPPET_HOME\hiera.yaml)
    $db_user = $(hiera db_user -c $PUPPET_HOME\hiera.yaml)
    $db_user_pwd = $(hiera db_user_pwd -c $PUPPET_HOME\hiera.yaml)
    
    . configure_java
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

function install_cerebro() {
    Write-Output "Installing Cerebro"

    iwr https://github.com/lmenezes/cerebro/releases/download/v0.9.0/cerebro-0.9.0.zip -outfile $env:TEMP\cerebro.zip
    expand-archive $env:TEMP\cerebro.zip -destination c:\app\

    $conf = @"
hosts = [
  {
   host = "http://localhost:9200"
   name = "Elasticsearch"
   auth = {
     username = "esadmin"
     password = "${ESADMIN_PWD}"
   }
  }
]    
"@

    add-content c:\app\cerebro-0.9.0\conf\application.conf $conf
}

function create_services() {
    
    # Elasticsearch
    Write-Output "Fixing Elasticsearch Service"
    nssm set elasticsearch-service-x64 Start SERVICE_AUTO_START
    
    # Kiabna
    Write-Output "Installing Kibana Service"
    nssm install kibana ${ELK_BASE_DIR}\pt\Kibana${ELK_VERSION}\bin\kibana.bat 
    nssm set kibana AppDirectory ${ELK_BASE_DIR}\pt\Kibana${ELK_VERSION}\bin
    nssm set kibana Start SERVICE_AUTO_START 
    nssm set kibana Description "Kibana ${ELK_VERSION}"
    start-service kibana

    # Logstash
    Write-Output "Installing Logstash Service"
    nssm install logstash "${ELK_BASE_DIR}\pt\Logstash${ELK_VERSION}\bin\logstash.bat"
    nssm set logstash AppParameters "-f ${ELK_BASE_DIR}\pt\Logstash${ELK_VERSION}\pt\config\LogstashPipeLine.CONF"
    nssm set logstash AppDirectory ${ELK_BASE_DIR}\pt\Logstash${ELK_VERSION}\bin
    nssm set logstash Start SERVICE_AUTO_START 
    nssm set logstash Description "Logstash ${ELK_VERSION}"
    nssm set logstash AppEnvironmentExtra LOGSTASH_HOME=${ELK_BASE_DIR}\pt\Logstash${ELK_VERSION}
    start-service logstash

    # Cerebro
    Write-Output "Installing Cerebro Service"
    nssm install cerebro "c:\app\cerebro-0.9.0\bin\cerebro.bat"
    nssm set cerebro AppDirectory "c:\app\cerebro-0.9.0"
    nssm set cerebro Start SERVICE_AUTO_START
    nssm set cerebro Description "Cerebro - Elasticsearch Monitoring"
    start-service cerebro    
}



function cleanup() {
    # Cleanup temp files
    Remove-Item $ELASTIC_HOME -recurse
    Remove-Item $LOGSTASH_HOME -recurse
    Remove-Item $JAVA_HOME -recurse
    Remove-Item $env:TEMP\cerebro.zip
}

$start_loc = $(get-location)

. determine_elk_version
. generate_response_file
. execute_psft_dpk_setup
. install_cerebro
. create_services
. cleanup

set-location $start_loc