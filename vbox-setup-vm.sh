#!/usr/bin/env bash

function promptyn() {
  while true; do
    read -p "$1 (Yes/No): " yn
    case $yn in
        [Yy]* ) echo "1"; break;;
        [Nn]* ) echo ""; break;;
        * ) echo "Please answer yes or no.";;
    esac
  done
}

echo "This is a guided script which will get you through the setup process of a VirtualBox VM."
echo "Before continuing prepare full paths of any HDD .vdi and/or CD/DVD .iso files which you plan to use with the VM."
echo "Press ENTER to continue."
read

while true; do
    read -p "Enter machine name: " NAME
    if [ $NAME ]; then break; fi
done
os_types=$(VBoxManage list ostypes | grep "^ID:" | cut -d " " -f 2- | sed 's/^ *//g')
echo "Choose OS type:"
select OS_TYPE in $os_types; do
  if [ $OS_TYPE ] ; then
    echo $OS_TYPE
    break;
  fi
done
read -ep "Enter CPU core count: " -i "1" CPU_CORES
read -ep "Enter RAM size (MB): " -i "1024" RAM
read -ep "Enter Video RAM size (MB): " -i "64" VIDEO_RAM

read -p "Enter full path to VDI file (the file will be COPIED) [none]: " HDD_VDI
if [[ -z $HDD_VDI ]]; then
  read -ep "Enter HDD size (GB): " -i "50" HDD_SIZE
fi
read -ep "Enter full path to an CD/DVD iso image [none]: " IDE_ISO
while true; do
    read -sp "Enter new RDP password: " RDP_PASSWD
    read -sp "Confirm RDP password: " RDP_CONFIRM_PASSWD
    if [ "$RDP_PASSWD" != "$RDP_CONFIRM_PASSWD" ]; then echo "Passwords do not match!"; continue; fi
    if [[ -z "$RDP_PASSWD" ]]; then echo "Password must not be empty!"; continue; fi
    break
done

echo
echo
echo "Summary:"
echo "--------"
echo "Machine name: $NAME"
echo "OS type: $OS_TYPE"
echo "CPU cores: $CPU_CORES"
echo "RAM size: $RAM MB"
echo "Video RAM size: $VIDEO_RAM MB"
echo "HDD copy VDI: $HDD_VDI"
if [[ $HDD_VDI ]]; then
  echo "HDD size: [using existing file]"
else
  echo "HDD size: $HDD_SIZE GB"
fi
#echo "RDP username: $RDP_USER"
echo "CD/DVD ISO image: $IDE_ISO"
echo -n "RDP password: "
printf '*%.0s' $(seq 1 ${#RDP_PASSWD})
echo
echo

if [[ -z $(promptyn "Continue with those parameters (the machine will be created)") ]]; then
  echo "Exit"
  exit;
fi

#while true; do
#    read -p "Continue with those parameters (Yes/No)? (the machine will be created): " yn
#    case $yn in
#        [Yy]* ) break;;
#        [Nn]* ) exit;;
#        * ) echo "Please answer yes or no.";;
#    esac
#done

set -e
DIR=$(VBoxManage list systemproperties | grep "Default machine folder:" | cut -d " " -f 4- | sed 's/^ *//g')
DIR="$DIR/$NAME"
HDD_SIZE=$(($HDD_SIZE*1024))

echo "Creating VM..."
VBoxManage createvm --name "$NAME" --register
cd "$DIR"

echo "Preparing control scripts..."

mkdir control

touch control/start
echo "#!/usr/bin/env bash" > control/start
echo "VBoxManage startvm \"$NAME\" --type headless" >> control/start
chmod +x control/start

touch control/stop
echo "#!/usr/bin/env bash" > control/stop
echo "VBoxManage controlvm \"$NAME\" poweroff" >> control/stop
chmod +x control/stop

touch control/delete
echo "#!/usr/bin/env bash" > control/delete
echo "set -e" >> control/delete
echo "read -p \"Are you sure you want to delete \\\"$NAME\\\"? (type uppercase YES to confirm): \" CONFIRM"  >> control/delete
echo "if [[ \"YES\" != \$CONFIRM ]]; then echo \"Exit\"; exit; fi" >> control/delete
echo "echo \"Deleting...\""  >> control/delete
echo "DIR=\$(dirname \"\$0\")" >> control/delete
echo "rm -r \"$DIR\""  >> control/delete
echo "VBoxManage unregistervm \"$NAME\" --delete" >> control/delete
echo "echo \"Done.\"" >> control/delete


echo "Setting up HDD..."
if [[ $HDD_VDI ]]; then
  rsync -vP "$HDD_VDI" "$DIR/$NAME.vdi"
  VBoxManage internalcommands sethduuid "$DIR/$NAME.vdi"
  #mv "/tmp/$NAME.vdi" "$DIR/"
  #VBoxManage clonehd "/tmp/$NAME.vdi" "$DIR/$NAME.vdi"
  #rm "/tmp/$NAME.vdi"
else
  VBoxManage createhd --filename "$NAME.vdi" --size $HDD_SIZE --format VDI
fi
VBoxManage storagectl "$NAME" --name SATA --add sata --controller IntelAhci --bootable on
VBoxManage storageattach "$NAME" --storagectl SATA --port 0 --device 0 --type hdd --medium "$DIR/$NAME.vdi"

echo "Setting VM parameters..."
VBoxManage modifyvm "$NAME" --ostype $OS_TYPE
VBoxManage modifyvm "$NAME" --cpus $CPU_CORES
VBoxManage modifyvm "$NAME" --memory $RAM
VBoxManage modifyvm "$NAME" --vram $VIDEO_RAM
VBoxManage modifyvm "$NAME" --nic1 nat --nictype1 82540EM --cableconnected1 on
VBoxManage modifyvm "$NAME" --acpi on --hpet on --ioapic on

echo "Configuring RDP access..."
VBoxManage modifyvm "$NAME" --vrde on
VBoxManage modifyvm "$NAME" --vrdeproperty VNCPassword="$RDP_PASSWD"
VBoxManage modifyvm "$NAME" --vrdeport 9600
VBoxManage modifyvm "$NAME" --vrdeauthlibrary null
#VBoxManage modifyvm "$NAME" --vrdeauthtype external
RDP_PASSWD_HASH=$(VBoxManage internalcommands passwordhash "$RDP_PASSWD" | cut -d " " -f 3)
VBoxManage setextradata "$NAME" "VBoxAuthSimple/users/$RDP_USER" $RDP_PASSWD_HASH

# DVD:
if [ $IDE_ISO ] ; then
  echo "Setting up DVD drive..."
  VBoxManage storagectl "$NAME" --name IDE --add ide --controller PIIX3 --bootable on
  VBoxManage storageattach "$NAME" --storagectl IDE --port 0 --device 0 --type dvddrive --medium "$IDE_ISO"
  VBoxManage modifyvm "$NAME" --acpi on
  VBoxManage modifyvm "$NAME" --boot1 dvd
  VBoxManage modifyvm "$NAME" --boot2 disk
fi



echo
echo "Done."
echo
echo "Additional configuration:"
echo "Set RDP auth: 'VBoxManage setproperty vrdeauthlibrary \"VBoxAuthSimple\"'"
echo "After system is installed: 'VBoxManage modifyvm \"$NAME\" --boot1 disk'"
echo "To run your VM in foreground: 'VBoxHeadless -s \"$NAME\"'"
echo "To run your VM in background: 'VBoxManage startvm \"$NAME\" --type headless"
echo "You might need a VNC client: apt-get install ssvnc; ssvncviewer host:port"
echo "To set up ssh port forwarding: 'VBoxManage modifyvm \"$NAME\" --natpf1 \"guestssh,tcp,,9601,,22\""
echo "To set up HTTP port forwarding: 'VBoxManage modifyvm \"$NAME\" --natpf1 \"guesthttp,tcp,,9702,,80\""
