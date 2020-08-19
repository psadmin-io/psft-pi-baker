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

def bootstrap():
    # & ./powershell/provision-bootstrap-ps.ps1 -PATCH_ID "$PI_PATCH_ID" -DPK_INSTALL "c:/psft/dpk/downloads/$PI_PATCH_ID" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet" >> $log
    logging.info("TODO")

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
    download()
    bootstrap()
    yaml()
    puppet_apply()
    util()
    done()

if __name__ == "__main__":
    main()
