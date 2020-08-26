#!/usr/bin/python3

import os
import logging
import subprocess

from shutil import copyfile
from pathlib import Path

# TODO - can these variables be "global" like this? - I think so, but we should refactor to minimize

MOS_USERNAME = os.getenv("MOS_USERNAME")
MOS_PASSWORD = os.getenv("MOS_PASSWORD")
PI_PATCH_ID  = os.getenv("PI_PATCH_ID")
ELK_PATCH_ID = os.getenv("ELK_PATCH_ID")

files_dir = os.path.dirname(os.path.realpath(__file__)) + "/files"
userdata_dir = os.path.dirname(os.path.realpath(__file__)) + "/userdata"
custom_dir = userdata_dir + "/custom"

# Logging
logpath = userdata_dir
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
    logging.debug("Banner start")

    logging.info("banner goes here TODO")

    logging.debug("Banner stop")

def setup_filesystem():

# TODO
#sudo yum -y install oracle-database-preinstall-19c glibc-devel

    try:
        logging.debug("Create base directory, if needed.")
        Path(psft_base_dir).mkdir(parents=True, exist_ok=True) # TODO - mode?
        logging.debug("Create dpk directory, if needed.")
        Path(dpk_dir).mkdir(parents=True, exist_ok=True) # TODO - mode?
        logging.debug("Create home directory, if needed.")
        Path(home_dir).mkdir(parents=True, exist_ok=True) # TODO - mode?
        logging.debug("Create PS_CFG_HOME directory, if needed.")
        Path(cfg_dir).mkdir(parents=True, exist_ok=True) # TODO - mode?

        # copyfile(files_dir + "/vagabond.json",userdata_dir) TODO
        # psft_cust.yaml? TODO
   
    except FileExistsError as e:
        logging.debug(e)
        pass

    except Exception as e:
        logging.error("There was an issue setting up the file system.")
        logging.error(e)

def download():
    # & ./powershell/provision-download.ps1 -MOS_USERNAME "$MOS_USERNAME" -MOS_PASSWORD "$MOS_PASSWORD" -PATCH_ID "$PI_PATCH_ID" -DPK_INSTALL "c:/psft/dpk/downloads/$PI_PATCH_ID" >> $log
    logging.info("Downloading DPK zip files. - SKIP TODO")

def bootstrap(dpk_files_dir, psft_base_dir, puppet_home):
    logging.info("Running DPK Bootstrap")

    # TODO - assumes zips are already unpacked in `download` step before

    # determine_tools_version
    #     # tools_version = $(Get-Content ${DPK_INSTALL}/setup/bs-manifest | select-string "version" | % {$_.line.split("=")[1]})
    #     # $TOOLS_MAJOR_VERSION = $TOOLS_VERSION.split(".")[0]
    #     # $TOOLS_MINOR_VERSION = $TOOLS_VERSION.split(".")[1]
    #     # $TOOLS_PATCH_VERSION = $TOOLS_VERSION.split(".")[2]

    # generate_response_file
    logging.debug("Generating response file")
    rsp_file = open(dpk_files_dir + "/response.cfg","w") 
    responses = [
        "psft_base_dir = \"" + psft_base_dir + "\"\n",
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
        setup_script = dpk_files_dir + "/setup/psft-dpk-setup.sh"
        dpk_logfile = open(userdata_dir + "/psft-dpk-setup.log","w")
        try:
            subprocess.run(["sh", setup_script, "--silent", "--dpk_src_dir " + dpk_files_dir, "--response_file " + dpk_files_dir + "/response.cfg", "--no_puppet_run"], stdout=dpk_logfile, stderr=dpk_logfile, check=True)
        except:
            logging.error("DPK bootstrap script failed.")

def yaml(puppet_home):
    logging.info("Copying psft_customizations.yaml")
    # TODO assuming data directory is there, add error check
    copyfile(custom_dir + "/psft_customizations.yaml", puppet_home + "/production/data/psft_customizations.yaml")

def puppet_apply(puppet_home):
    logging.info("TODO")
  
    # execute_puppet_apply
    # TODO - keep for future windows usage?
    # Reset Environment and PATH to include bin\puppet
    # $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
    try:
        dpk_logfile = open(userdata_dir + "/psft-dpk-apply.log","w")
        subprocess.run(["sudo","/opt/puppetlabs/bin/puppet", "apply", puppet_home + "/production/manifests/site.pp", "--confdir=" + puppet_home, "--trace", "--debug"], check=True, stdout=dpk_logfile, stderr=dpk_logfile)
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
    # TODO
    psft_base_dir = "/u01/app/oracle/product"
    dpk_files_dir = userdata_dir + "/11"
    dpk_dir       = psft_base_dir + "/dpk" # TODO - actually use hostname here, like CM does?
    home_dir      = psft_base_dir + "/hostname/home" # TODO - actually use hostname here, like CM does?
    cfg_dir       = psft_base_dir + "/hostname/ps_cfg_home" # TODO - actually use hostname here, like CM does?
    puppet_home   = dpk_dir + "/puppet" # TODO - install dpk/ in 
    
    banner()
    setup_filesystem()
    download()
    bootstrap(dpk_files_dir, psft_base_dir, puppet_home)
    yaml(puppet_home)
    puppet_apply(puppet_home)
    util()
    done()

if __name__ == "__main__":
    main()