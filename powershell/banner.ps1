function echobanner-output{
  Write-Output "######################################################"
  Write-Output "                ... psft-pi-baker ...                 "
  Write-Output "######################################################"
}

function echobanner-host {
  Write-Host "`n`n"
  Write-Host "  ,---.    .---. ,---. _______                          " -foregroundcolor DarkRed
  Write-Host "  | .-.\  ( .-._)| .-'|__   __|                         " -foregroundcolor DarkRed
  Write-Host "  | |-' )(_) \   | ``-.  )| |                            " -foregroundcolor DarkRed
  Write-Host "  | |--' _  \ \  | .-' (_) |     " -foregroundcolor DarkRed -NoNewline; Write-Host " )" -foregroundcolor DarkYellow
  Write-Host "  | |   ( ``-'  ) | |     | |    " -foregroundcolor DarkRed -NoNewline; Write-Host " (                   " -foregroundcolor DarkYellow
  Write-Host "  /(     ``----'  )\|     ``-'   " -foregroundcolor DarkRed -NoNewline; Write-Host "   )                   " -foregroundcolor DarkYellow
  Write-Host " (__)           (__)             " -foregroundcolor DarkRed -NoNewline; Write-Host "(                   " -foregroundcolor DarkYellow
  Write-Host "                                  )                      " -foregroundcolor DarkYellow 
  Write-Host "       ,---.  ,-.                " -foregroundcolor DarkRed -NoNewline; Write-Host "(                      " -foregroundcolor DarkYellow 
  Write-Host "       | .-.\ |(|           " -foregroundcolor DarkRed -NoNewline; Write-Host "__..---..__                         " -foregroundcolor DarkYellow 
  Write-Host "       | |-' )(_)       " -foregroundcolor DarkRed -NoNewline; Write-Host ",-='  /  |  \  ``=-.                        " -foregroundcolor DarkYellow
  Write-Host "       | |--' | |      " -foregroundcolor DarkRed -NoNewline; Write-Host ":--..___________..--;                               " -foregroundcolor DarkYellow
  Write-Host "       | |    | |       " -foregroundcolor DarkRed -NoNewline; Write-Host "\.,_____________,./" -foregroundcolor DarkYellow
  Write-Host "       /(     ``-'                                       " -foregroundcolor DarkRed
  Write-Host "      (__)                                         " -foregroundcolor DarkRed
  Write-Host "              ,---.     .--.  ,-. .-.,---.  ,---.      " -foregroundcolor DarkRed
  Write-Host "              | .-.\   / /\ \ | |/ / | .-'  | .-.\     " -foregroundcolor DarkRed
  Write-Host "              | |-' \ / /__\ \| | /  | ``-.  | ``-'/     " -foregroundcolor DarkRed
  Write-Host "              | |--. \|  __  || | \  | .-'  |   (      " -foregroundcolor DarkRed
  Write-Host "              | |``-' /| |  |)|| |) \ |  ``--.| |\ \     " -foregroundcolor DarkRed
  Write-Host "              /( ``--' |_|  (_)|((_)-'/( __.'|_| \)\    " -foregroundcolor DarkRed
  Write-Host "             (__)             (_)   (__)        (__)   " -foregroundcolor DarkRed
  
  
  # Write-Host "             (               " -foregroundcolor DarkYellow
  # Write-Host "              )              " -foregroundcolor DarkYellow
  # Write-Host "             (               " -foregroundcolor DarkYellow
  # Write-Host "              )              " -foregroundcolor DarkYellow
  # Write-Host "         __..---..__         " -foregroundcolor DarkYellow
  # Write-Host "     ,-='  /  |  \  `=-.     " -foregroundcolor DarkYellow
  # Write-Host "    :--..___________..--;    " -foregroundcolor DarkYellow
  # Write-Host "     \.,_____________,./     " -foregroundcolor DarkYellow
  Write-Host "`n`n"
}





function install_powershell () {
  (Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')))
  C:\ProgramData\chocolatey\bin\choco.exe install powershell -y
  Restart-Computer
}
. echobanner-host
. echobanner-output
# . install_powershell