
  # init
  Set-ExecutionPolicy RemoteSigned -force
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls13, [Net.SecurityProtocolType]::Tls12 
  New-Item -ItemType directory -Path "c:/temp" #todo pass location?
  Push-Location "c:/temp"
  (Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')))
  refreshenv
  choco install git -y
  refreshenv # todo refresh is not working?
  C:\PROGRA~1\Git\bin\git clone https://github.com/psadmin-io/psft-pi-baker.git
  # install
  ./psft-pi-baker/bake.ps1 -MOS_USERNAME "${mos_username}" -MOS_PASSWORD "${mos_password}" -MOS_PATCH_ID "${mos_patch_id}"