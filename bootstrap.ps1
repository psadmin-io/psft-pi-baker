# init
Set-ExecutionPolicy RemoteSigned -force
cd "c:/temp"
(Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')))
choco install git -y
git clone https://github.com/psadmin-io/psft-pi-baker.git
# install
./psft-pi-baker/win2016.ps1