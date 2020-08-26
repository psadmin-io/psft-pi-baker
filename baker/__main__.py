#!/usr/bin/python3

import os
import logging
import subprocess

from shutil import copyfile
from pathlib import Path

class Baker:
    # empty class used for module level variable scope
    pass

__m = Baker()

def init():
    __m.mos_username  = os.getenv("MOS_USERNAME")
    __m.mos_password  = os.getenv("MOS_PASSWORD")
    __m.pi_patch_id   = os.getenv("PI_PATCH_ID")
    __m.elk_patch_id  = os.getenv("ELK_PATCH_ID")

    __m.files_dir     = os.path.dirname(os.path.realpath(__file__)) + "/files"
    __m.userdata_dir  = os.path.dirname(os.path.realpath(__file__)) + "/userdata"
    __m.custom_dir    = __m.userdata_dir + "/custom"
    __m.psft_base_dir = "/u01/app/oracle/product"

    __m.dpk_files_dir = __m.userdata_dir + "/11"
    __m.dpk_dir       = __m.psft_base_dir + "/dpk" # TODO - actually use hostname here, like CM does?
    __m.home_dir      = __m.psft_base_dir + "/hostname/home" # TODO - actually use hostname here, like CM does?
    __m.cfg_dir       = __m.psft_base_dir + "/hostname/ps_cfg_home" # TODO - actually use hostname here, like CM does?
    __m.puppet_home   = __m.dpk_dir + "/puppet" # TODO - install dpk/ in 


    # Logging
    logpath = __m.userdata_dir
    logfile = "psft-pi-baker.log"
    loglevel = logging.DEBUG 
    rootLogger = logging.getLogger()
    rootLogger.setLevel(loglevel)

    fileHandler = logging.FileHandler("{0}/{1}".format(logpath, logfile))
    fileFormatter = logging.Formatter("%(asctime)s [%(threadName)-12.12s] [%(levelname)-5.5s]  %(message)s")
    fileHandler.setFormatter(fileFormatter)
    fileHandler.setLevel(loglevel)
    rootLogger.addHandler(fileHandler)

    consoleHandler = logging.StreamHandler()
    consoleFormatter = logging.Formatter("[%(levelname)-5.5s]  %(message)s")
    consoleHandler.setFormatter(consoleFormatter)
    consoleHandler.setLevel(loglevel)
    rootLogger.addHandler(consoleHandler)

    # CRITICAL 50
    # ERROR    40
    # WARNING  30
    # INFO     20
    # DEBUG    10

def banner():
    logging.info("banner goes here TODO")

def setup_filesystem():
    try:
        logging.debug("Create base directory, if needed." + __m.psft_base_dir)
        Path(__m.psft_base_dir).mkdir(parents=True, exist_ok=True) # TODO - mode?
        logging.debug("Create dpk directory, if needed.")
        Path(__m.dpk_dir).mkdir(parents=True, exist_ok=True) # TODO - mode?
        logging.debug("Create home directory, if needed.")
        Path(__m.home_dir).mkdir(parents=True, exist_ok=True) # TODO - mode?
        logging.debug("Create PS_CFG_HOME directory, if needed.")
        Path(__m.cfg_dir).mkdir(parents=True, exist_ok=True) # TODO - mode?

        # copyfile(files_dir + "/vagabond.json",userdata_dir) TODO
        # psft_cust.yaml? TODO
   
    except FileExistsError as e:
        logging.debug(e)
        pass

    except Exception as e:
        logging.error("There was an issue setting up the file system.")
        logging.error(e)

def setup_packages():
    logging.info("TODO - make sure required packages are intalled!")
    # TODO
    #sudo yum -y install oracle-database-preinstall-19c glibc-devel

def download():
    # & ./powershell/provision-download.ps1 -MOS_USERNAME "$MOS_USERNAME" -MOS_PASSWORD "$MOS_PASSWORD" -PATCH_ID "$PI_PATCH_ID" -DPK_INSTALL "c:/psft/dpk/downloads/$PI_PATCH_ID" >> $log
    logging.info("Downloading DPK zip files. - SKIP TODO")

def bootstrap():
    logging.info("Running DPK Bootstrap")

    # TODO - assumes zips are already unpacked in `download` step before

    # determine_tools_version
    #     # tools_version = $(Get-Content ${DPK_INSTALL}/setup/bs-manifest | select-string "version" | % {$_.line.split("=")[1]})
    #     # $TOOLS_MAJOR_VERSION = $TOOLS_VERSION.split(".")[0]
    #     # $TOOLS_MINOR_VERSION = $TOOLS_VERSION.split(".")[1]
    #     # $TOOLS_PATCH_VERSION = $TOOLS_VERSION.split(".")[2]

    # generate_response_file
    logging.debug("Generating response file")
    rsp_file = open(__m.dpk_files_dir + "/response.cfg","w") 
    responses = [
        "psft_base_dir = \"" + __m.psft_base_dir + "\"\n",
        "install_type = \"PUM\"\n",
        "env_type  = \"fulltier\"\n",
        "db_type = \"DEMO\"\n",
        "db_name = \"PSFTDB\"\n",
        "db_service_name = \"PSFTDB\"\n",
        "db_host = \"localhost\"\n",
        "admin_pwd = \"Passw0rd_\"\n",
        "connect_pwd = \"peop1e\"\n",
        "access_pwd  = \"SYSADM\"\n",
        "opr_pwd = \"PS\"\n",
       # "domain_conn_pwd = \"P@ssw0rd_\"\n",
        "weblogic_admin_pwd  = \"Passw0rd#\"\n",
        "webprofile_user_pwd = \"PTWEBSERVER\"\n",
        "gw_user_pwd = \"password\"\n",
        "gw_keystore_pwd = \"password\"\n",
    ]
    rsp_file.writelines(responses)
    rsp_file.close()

    # execute_psft_dpk_setup
    logging.debug("Executing DPK Setup")

    if os.name == 'nt':
        logging.warning("Windows is not supported at this time.")
    else:
        setup_script = __m.dpk_files_dir + "/setup/psft-dpk-setup.sh"
        dpk_logfile = open(__m.userdata_dir + "/psft-dpk-setup.log","w")
        try:
            subprocess.run(["sh", setup_script, "--silent", "--dpk_src_dir " + __m.dpk_files_dir, "--response_file " + __m.dpk_files_dir + "/response.cfg", "--no_puppet_run"], stdout=__m.dpk_logfile, stderr=dpk_logfile, check=True)
        except:
            logging.error("DPK bootstrap script failed.")

def yaml():
    logging.info("Copying psft_customizations.yaml")
    # TODO assuming data directory is there, add error check
    copyfile(__m.custom_dir + "/psft_customizations.yaml", __m.puppet_home + "/production/data/psft_customizations.yaml")

def puppet_apply():
    logging.info("TODO")
  
    # execute_puppet_apply
    # TODO - keep for future windows usage?
    # Reset Environment and PATH to include bin\puppet
    # $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
    try:
        dpk_logfile = open(__m.userdata_dir + "/psft-dpk-apply.log","w")
        subprocess.run(["sudo","/opt/puppetlabs/bin/puppet", "apply", __m.puppet_home + "/production/manifests/site.pp", "--confdir=" +__m.puppet_home, "--trace", "--debug"], check=True, stdout=dpk_logfile, stderr=dpk_logfile)
        #subprocess.run(["sudo","/opt/puppetlabs/bin/puppet", "--version"], check=True, stdout=dpk_logfile, stderr=dpk_logfile)
    except:
        logging.error("Puppet apply failed.")
    
def util():
    # & ./powershell/provision-utilities.ps1 >> $log
    logging.info("TODO-util")

    # # Fix Ruby Gems CA
  # https://gist.github.com/iversond/772e73257c4ca59a9e6137baa7288788
  # $CACertFile = Join-Path -Path $ENV:AppData -ChildPath 'RubyCACert.pem'

  # If (-Not (Test-Path -Path $CACertFile)) {  
    #"Downloading CA Cert bundle.."
  #   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  #   Invoke-WebRequest -Uri 'https://curl.haxx.se/ca/cacert.pem' -UseBasicParsing -OutFile $CACertFile | Out-Null
  # }

  # Update PATH
  # Write-Output "[${env:COMPUTERNAME}] Adding gem and git to PATH"
  # $env:PATH+=";C:\Program Files\Puppet Labs\Puppet\sys\ruby\bin;C:\Program Files\Git\bin"
  # [System.Environment]::SetEnvironmentVariable('PATH',$env:PATH, [System.EnvironmentVariableTarget]::Machine)

  # "Setting CA Certificate store set to $CACertFile.."
 #  $ENV:SSL_CERT_FILE = $CACertFile
 #  [System.Environment]::SetEnvironmentVariable('SSL_CERT_FILE',$CACertFile, [System.EnvironmentVariableTarget]::Machine)

#   gem install psadmin_plus
# }

# function install_browsers() {
#   Write-Output "[${env:COMPUTERNAME}] Installing Browsers"
#   choco install googlechrome -y
# 	choco install firefox -y
# }

# function install_code_management() {
#   Write-Output "[${env:COMPUTERNAME}] Installing Code Management Software"
# }  choco install VSCode -y
# 	choco install git -y

def done():
    logging.info("Done.")

def main():    
    init()
    banner()
    setup_filesystem()
    setup_packages()
    download()
    bootstrap()
    yaml()
    puppet_apply()
    util()
    done()

if __name__ == "__main__":
    main()