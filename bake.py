import os
import logging

from shutil import copyfile

MOS_USERNAME = os.environ["MOS_USERNAME"]
MOS_PASSWORD = os.environ["MOS_PASSWORD"]
PI_PATCH_ID  = os.environ["PI_PATCH_ID"]
ELK_PATCH_ID = os.environ["ELK_PATCH_ID"]

logfile  = "c:\temp\psft-pi-baker.log" # TODO
loglevel = logging.DEBUG 
logging.basicConfig(filename=logfile, level=loglevel)

files_dir = os.path.dirname(os.path.realpath(__file__)) + "/files"
userdata_dir = os.path.dirname(os.path.realpath(__file__)) + "/userdata"

# CRITICAL 50
# ERROR    40
# WARNING  30
# INFO     20
# DEBUG    10

#     Push-Location $PSScriptRoot

#     Function log($msg) {
#         $stamp = [DateTime]::Now.ToString("yyyyMMdd-HHmmss")
#         Add-Content $log "[$stamp] $msg"
#     }
#     Function info($msg) {
#         log("INFO: $msg")
#     }
#     Function debug($msg) {
#         log("DEBUG: $msg")
#     }
#     Function error($msg) {
#         log("ERROR: $msg")
#     }    


def banner():
    puts "banner goes here TODO"

def setup_filesystem():
    
    base_dir = "/u01/app/oracle/product"
    dpk_dir  = base_dir + "hostname/dpk" # TODO - actually use hostname here, like CM does?
    home_dir  = base_dir + "hostname/home" # TODO - actually use hostname here, like CM does?
    cfg_dir  = base_dir + "hostname/ps_cfg_home" # TODO - actually use hostname here, like CM does?

    try:
        os.makedirs(base_dir) # TODO - mode?
        os.makedirs(dpk_dir) # TODO - mode?
        os.makedirs(home_dir) # TODO - mode?
        os.makedirs(cfg_dir) # TODO - mode?

        # copyfile(files_dir + "/vagabond.json",userdata_dir) TODO
        # psft_cust.yaml? TODO
    
    except:
        puts "Error - TODO"

def download():
    # & ./powershell/provision-download.ps1 -MOS_USERNAME "$MOS_USERNAME" -MOS_PASSWORD "$MOS_PASSWORD" -PATCH_ID "$PI_PATCH_ID" -DPK_INSTALL "c:/psft/dpk/downloads/$PI_PATCH_ID" >> $log
    
def bootstrap():
    # & ./powershell/provision-bootstrap-ps.ps1 -PATCH_ID "$PI_PATCH_ID" -DPK_INSTALL "c:/psft/dpk/downloads/$PI_PATCH_ID" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet" >> $log

def yaml():
    # & ./powershell/provision-yaml.ps1 -DPK_INSTALL "c:/psft/dpk/downloads/$PI_PATCH_ID" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet" >> $log

def puppet_apply():
    # & ./powershell/provision-puppet-apply.ps1 -DPK_INSTALL "c:/psft/dpk/downloads/$PI_PATCH_ID" -PSFT_BASE_DIR "c:/psft" -PUPPET_HOME "c:/psft/dpk/puppet" >> $log
    
def util():
    # & ./powershell/provision-utilities.ps1 >> $log

def done():
    # done banner?

def main():
    banner
    setup_filesystem()
    download()
    bootstrap()
    yaml()
    puppet_apply()
    util()
    done()

if __name__ == "__main__":
    main()
