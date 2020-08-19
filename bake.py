import os
import logging

from shutil import copyfile
from pathlib import Path

MOS_USERNAME = os.getenv("MOS_USERNAME")
MOS_PASSWORD = os.getenv("MOS_PASSWORD")
PI_PATCH_ID  = os.getenv("PI_PATCH_ID")
ELK_PATCH_ID = os.getenv("ELK_PATCH_ID")

files_dir = os.path.dirname(os.path.realpath(__file__)) + "/files"
userdata_dir = os.path.dirname(os.path.realpath(__file__)) + "/userdata"

# Logging
logpath = "."
logfile  = "psft-pi-baker.log" # TODO
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

    print("banner goes here TODO")

    logging.debug("Banner stop")

def setup_filesystem():
    
    logging.debug("Create base directory, if needed.")
    base_dir = "/u01/app/oracle/product"
    logging.debug("Create dpk directory, if needed.")
    dpk_dir  = base_dir + "/hostname/dpk" # TODO - actually use hostname here, like CM does?
    logging.debug("Create home directory, if needed.")
    home_dir  = base_dir + "/hostname/home" # TODO - actually use hostname here, like CM does?
    logging.debug("Create PS_CFG_HOME directory, if needed.")
    cfg_dir  = base_dir + "/hostname/ps_cfg_home" # TODO - actually use hostname here, like CM does?

    try:
        Path(base_dir).mkdir(parents=True, exist_ok=True) # TODO - mode?
        Path(dpk_dir).mkdir(parents=True, exist_ok=True) # TODO - mode?
        Path(home_dir).mkdir(parents=True, exist_ok=True) # TODO - mode?
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
    logging.info("Downloading DPK zip files. - TODO")

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
    rsp_file = open(dpk_files_dir + "/response.cfg") # TODO mode?
    responses = [
        "psft_base_dir = \"${PSFT_BASE_DIR}\"",
        "install_type = \"PUM\"",
        "env_type  = \"fulltier\"",
        "db_type = \"DEMO\"",
        "db_name = \"PSFTDB\"",
        "db_service_name = \"PSFTDB\"",
        "db_host = \"localhost\"",
        "admin_pwd = \"Passw0rd_\"",
        "connect_pwd = \"peop1e\"",
        "access_pwd  = \"SYSADM\"",
        "opr_pwd = \"PS\"",
        "domain_conn_pwd = \"P@ssw0rd_\"",
        "weblogic_admin_pwd  = \"Passw0rd#\"",
        "webprofile_user_pwd = \"PTWEBSERVER\"",
        "gw_user_pwd = \"password\"",
    ]
    rsp_file.writelines(responses)

# execute_psft_dpk_setup
    # logging.debug("Executing DPK Setup")

#             . "${DPK_INSTALL}/setup/psft-dpk-setup.bat" `
#             --silent `
#             --dpk_src_dir "${DPK_INSTALL}" `
#             --response_file "${DPK_INSTALL}/response.cfg" `
#             --no_puppet_run

def yaml():
    # & ./powershell/provision-yaml.ps1 -DPK_INSTALL "c:/psft/dpk/downloads/$PI_PATCH_ID" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet" >> $log
    logging.info("TODO")

def puppet_apply():
    # & ./powershell/provision-puppet-apply.ps1 -DPK_INSTALL "c:/psft/dpk/downloads/$PI_PATCH_ID" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet" >> $log
    logging.info("TODO")
    
def util():
    # & ./powershell/provision-utilities.ps1 >> $log
    logging.info("TODO")

def done():
    # done banner?
    logging.info("TODO")

def main():
    banner()
    setup_filesystem()
    # download()
    bootstrap(dpk_files_dir, psft_base_dir, puppet_home)
    # yaml()
    # puppet_apply()
    # util()
    # done()

if __name__ == "__main__":
    main()
