$vm = "C:\Users\Jay\Documents\Virtual Machines\CentOS 7 64-bit\CentOS 7 64-bit.vmx"
$vmrun = "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe"
$gu = "jay"
$gp = "pass4021"
$pbkh = "D:\Home\Documents\ansible\test.yml"
$pbkg = "/tmp/test.yml"

try {
  if (get-process "vmware-vmx") {
    $existingvmprocess = $true
  }
  else {
    $existingvmprocess = $false
  }
}
catch { $existingvmprocess = $false }

if ($existingvmprocess -ne $true) {
  # No image running, kill additional VM processes
  try {
    get-process "vmware" | stop-process -Force
  }
  catch { 
  }
  #Start the vm
  & $vmrun start $vm nogui
}

# Machine start up test
$machineon = $false
$timeout = 0
while ($machineon -ne $true) {
  Start-Sleep -Seconds 1


  $result = & $vmrun -gu $gu -gp $gp fileExistsInGuest $vm "/etc/passwd" | Out-String
  #$result
  if ($result -like "*exists*") {
    $machineon = $true
  }
  $timeout = $timeout + 1
  if ($timeout -eq 120) {
    "Failed to start machine"; exit 
  }
}

if ($machineon) {

  # copy the playbook
  & $vmrun -gu root -gp $gp copyFileFromHostToGuest $vm $pbkh $pbkg

  #run the script
  & $vmrun -gu root -gp $gp runProgramInGuest $vm /usr/bin/ansible-playbook $pbkg

  # delete files
  & $vmrun -gu root -gp $gp deleteFileInGuest $vm $pbkg
  start-sleep -seconds 10

#  & $vmrun -gu root -gp $gp deleteFileInGuest $vm /tmp/playbookscripttest

  # Shutdown VM
  if ($existingvmprocess -eq $false) {
    & $vmrun stop $vm soft
  }

  remove-item "c:\users\jay\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt" -whatif

}
