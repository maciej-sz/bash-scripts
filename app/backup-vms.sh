#!/usr/bin/env bash

logfile="/var/log/backup-vms.log"

vms=("Jira" "Bitbucket", "Confluence" "Git" "ArtgeistMavenRepo" "DropFeeds" "AllPlait" "StaticStabloteam" "WzService" "Model")

#vms=("Git")

function stopVm {
    /usr/bin/VBoxManage controlvm "${vms[$i]}" acpipowerbutton >> "${logfile}" 2>&1
    while [[ "" != $(/usr/bin/VBoxManage list runningvms | grep "$1") ]]; do
        sleep 1
    done
}

for i in ${!vms[*]}
do
    echo -e "------------------------------" >> "${logfile}"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] Backing up VM \"${vms[$i]}\"..." >> "${logfile}"

    is_running=$(/usr/bin/VBoxManage list runningvms | grep "${vms[$i]}")

    if [[ "" == "${is_running}" ]] ; then
        echo "VM ${vms[$i]} is already stopped." >> "${logfile}"
    else 
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stopping VM..." >> "${logfile}"
        stopVm "${vms[$i]}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] VM \"${vms[$i]}\" stopped." >> "${logfile}"
    fi

    mkdir -p "/home/maciek/VirtualBox Backups/${vms[$i]}"
    rsync -avP "/home/maciek/VirtualBox VMs/${vms[$i]}/" "/home/maciek/VirtualBox Backups/${vms[$i]}/" >> "${logfile}" 2>&1
    
    if [[ "" != "${is_running}" ]] ; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting VM..." >> "${logfile}"
        /usr/bin/VBoxManage startvm "${vms[$i]}" --type headless >> "${logfile}" 2>&1
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] VM \"${vms[$i]}\" backed up." >> "${logfile}"
done
