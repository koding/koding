#!/bin/bash
LOG="/tmp/create_lvm.log"

DEVICE="/dev/xvdg"
PV="${DEVICE}1"
VG="vg0"
LV="fs_mongo"
MPOINT="/var/lib/mongo"


if [ ! -f /etc/new_server ]; then
    echo "file /etc/new_server not found" >>${LOG}
    exit 1
fi

# important checks
if /sbin/pvs -o pv_name --noheadings | grep "dev" ; then
	echo "Physical volume already exists!" >>${LOG}
	exit 1
fi


if [ -b ${DEVICE} ];then
	if ! /sbin/parted ${DEVICE} --script mklabel msdos 2>${LOG};then
		echo "Can't create label on device ${DEVICE}" >> ${LOG}
		exit 1
	else
		echo "Label on device ${DEVICE} has been created" >> ${LOG}
	fi
else
	echo "Can't find device ${DEVICE}" >> ${LOG}
	exit 1
fi


if [ -b ${DEVICE} ];then
	if ! /sbin/parted ${DEVICE} --script -- mkpart primary 1 -1 2>${LOG};then
		echo "Can't create partition on device ${DEVICE}" >> ${LOG}
		exit 1
	else
		echo "Partition on device ${DEVICE} has been created" >> ${LOG}
	fi
else
	echo "Can't find device ${DEVICE}" >> ${LOG}
	exit 1
fi

if ! /sbin/pvcreate ${PV} 2>>${LOG} 1>/dev/null ;then
	echo "Cant' create physical volume on ${PV}" >> ${LOG}
	exit 1
else
	echo "Physical volume ${PV} has been created" >> ${LOG}
	echo "Creating volume group" >> ${LOG}
	if ! /sbin/vgcreate ${VG} ${PV} 2>>${LOG} 1>/dev/null;then
		echo "Can't create VG" >>${LOG}
		exit 1
	else
		echo "VG ${VG} has been created" >>${LOG}
		echo "Creating logical volume" >>${LOG}
		if ! /sbin/lvcreate -n ${LV} -l100%FREE ${VG} 2>>${LOG} 1>/dev/null ;then
			echo "Can't create logical volume ${LV}" >>${LOG}
			exit 1
		else
			echo "LV ${LV} has been created" >>${LOG}
			if ! /sbin/mkfs.ext4 /dev/${VG}/${LV} 2>>${LOG} ;then
				echo "Can't create FS /dev/${VG}/${LV}" >>${LOG}
				exit 1
			else
				echo "FS /dev/${VG}/${LV} has been created" >>${LOG}
			fi
		fi
	fi
fi
			

if rm /etc/new_server 2>>${LOG};then
	echo "new_server file has been removed" >>${LOG}
else
	echo "/etc/new_server file wasnt removed!!" >>${LOG}
	exit 1
fi


exit 0
