##!/bin/bash
#############################################################################################
#	Edit the first 13 variables to match your options:
#	-----------------------------------------------------------------------------------------
#	QTVERSION=The Qt version you want to install for cross-compiling
#	see: https://code.qt.io/cgit/qt/qt5.git
#	-----------------------------------------------------------------------------------------
#	OPENCV_VERSION=The OpenCV version you want to install for cross-compiling
#	see: https://opencv.org/releases.html
#	-----------------------------------------------------------------------------------------
#	LIBGPHOTO2_VERSION=The libgphoto2 version you want to install for cross-compiling
#	see: http://gphoto.org/
#	-----------------------------------------------------------------------------------------
######	LIBUSB_VERSION=The Qt version you want to install for cross-compiling
#	-----------------------------------------------------------------------------------------
#	WIRNIGPICOMMIT=The wiringPi version (commit code) you want to install for cross-compiling
#	Go to: https://git.drogon.net/?p=wiringPi;a=summary - click on commit link of the master
#	version and copy the commit code to the variable
#	-----------------------------------------------------------------------------------------
#	USERNAME=Username on PC
#	-----------------------------------------------------------------------------------------
#	PIUSERNAME=Username on Raspberry Pi
#	-----------------------------------------------------------------------------------------
#	FLAGNONFS - Set to 0 if a NFS server is available.
#               Set to 1 if there is no nfs server available. 
#	-----------------------------------------------------------------------------------------
#	SERVERUSERNAME=Username on server (for nfs option)
#	-----------------------------------------------------------------------------------------
#	PI_IP=IP of the Raspberry Pi
#	-----------------------------------------------------------------------------------------
#	PI_IP_NFS=IP of the raspberry Pi booted from NFS
#	-----------------------------------------------------------------------------------------
#	SERVERIP=IP of the NFS server
#	-----------------------------------------------------------------------------------------
#	SERVERNFSDIR=Path of the NFS share on the server
#	-----------------------------------------------------------------------------------------
#	CPUCORES=number of CPU cores for multithread building (you can set this variable to
#   number of PC CPU cores * 1.5)
#############################################################################################
#############################################################################################
#								Variables section
#############################################################################################
	QTVERSION=5.10.1

#QTVERSION=5.11
#Makefile:3036: recipe for target '.obj/qeglfskmsgbmwindow.o' failed
#make[6]: *** [.obj/qeglfskmsgbmwindow.o] Error 1
#make[6]: Leaving directory '/home/rmf/raspi/qt-5.11/qtbase/src/plugins/platforms/eglfs/deviceintegration/eglfs_kms'
#Makefile:84: recipe for target 'sub-eglfs_kms-install_subtargets' failed
#make[5]: *** [sub-eglfs_kms-install_subtargets] Error 2
#make[5]: Leaving directory '/home/rmf/raspi/qt-5.11/qtbase/src/plugins/platforms/eglfs/deviceintegration'
#Makefile:128: recipe for target 'sub-deviceintegration-install_subtargets-ordered' failed
#make[4]: *** [sub-deviceintegration-install_subtargets-ordered] Error 2
#make[4]: Leaving directory '/home/rmf/raspi/qt-5.11/qtbase/src/plugins/platforms/eglfs'
#Makefile:137: recipe for target 'sub-eglfs-install_subtargets' failed
#make[3]: *** [sub-eglfs-install_subtargets] Error 2
#make[3]: Leaving directory '/home/rmf/raspi/qt-5.11/qtbase/src/plugins/platforms'
#Makefile:114: recipe for target 'sub-platforms-install_subtargets' failed
#make[2]: *** [sub-platforms-install_subtargets] Error 2
#make[2]: Leaving directory '/home/rmf/raspi/qt-5.11/qtbase/src/plugins'
#Makefile:788: recipe for target 'sub-plugins-install_subtargets' failed
#make[1]: *** [sub-plugins-install_subtargets] Error 2
#make[1]: Leaving directory '/home/rmf/raspi/qt-5.11/qtbase/src'
#Makefile:60: recipe for target 'sub-src-install_subtargets' failed
#make: *** [sub-src-install_subtargets] Error 2


	OPENCV_VERSION=3.4.1
	LIBGPHOTO2_VERSION=2.5.16
#	LIBUSB_VERSION=1.0.21
	WIRNIGPICOMMIT=96344ff7125182989f98d3be8d111952a8f74e15
	USERNAME=rmf
	PIUSERNAME=pi
	FLAGNONFS=0
	SERVERUSERNAME=pajafleger
	PI_IP="192.168.111.27"
	PI_IP_NFS="192.168.111.123"
	SERVERIP="192.168.111.200"
	SERVERNFSDIR=/nfs-export/RPI
	CPUCORES=12
	LOCALE=en_US.UTF-8
#############################################################################################
#     You do not need to edit below this line!
#############################################################################################
	WIRINGPI_VERSION=wiringPi-${WIRNIGPICOMMIT:0:7}
	QTCOMPILEDVERSION_PC=qt5pc
	QTCOMPILEDVERSION_PI=qt5pi
	RPILOGIN="$PIUSERNAME@$PI_IP"
	SERVERLOGIN="$SERVERUSERNAME@$SERVERIP"
	RPI_SD_ROOTFS=/media/$USERNAME/rootfs
	WORKDIR=/home/$USERNAME/raspi
	QTDIR=$WORKDIR/qt-$QTVERSION
	LOGDIR=$WORKDIR/log
	PIROOT=$WORKDIR/piroot
	SYSROOT=$WORKDIR/sysroot
	NFSDIR=$WORKDIR/nfs
	RPINFSVERSION=raspbian-stretch-fw-crosscompiling/rootfs
	NFSROOT=$NFSDIR/RPI-common/$RPINFSVERSION
	SERVERNFSROOT=$SERVERNFSDIR/RPI-common/$RPINFSVERSION
	CROSS_BUILT=$WORKDIR/cross_built
#############################################################################################
#								End variables section
#############################################################################################

#https://github.com/Hexxeh/rpi-firmware/commits/master
#4.14.21
#ab90bf1971e4b6cd8c75d6ff7c20bf08166b613e


OURNAME=$0
FUNCTION=$1
FUNCPARAM=$2
HOSTNAME=$(cat /etc/hostname)
NET_IF=`netstat -rn | awk '/^0.0.0.0/ {thif=substr($0,74,10); print thif;} /^default.*UG/ {thif=substr($0,65,10); print thif;}'`
OWNIP=`ifconfig ${NET_IF} | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
if [ -z $SERVERIP ]
then
	FLAGNONFS=1
fi



makefolders()
{
	mkdir $WORKDIR
	mkdir $SYSROOT
	mkdir $PIROOT
	mkdir $NFSDIR
	mkdir $CROSS_BUILT
	mkdir $CROSS_BUILT/lib
	mkdir $CROSS_BUILT/local
	mkdir $LOGDIR
	echo "Folders were generated."
}

installpcprogs()
{
	echo "Installing PC programs..."
	sudo apt-get install -y sshfs
	sudo apt-get install -y nfs-common
	sudo apt-get install -y cmake
	sudo apt-get install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf
	sudo apt-get install -y libusb-1.0.0-dev libusb-1.0-0
	sudo apt-get install -y libusb-dev
	sudo apt-get install -y git
	sudo apt-get install -y gphoto2 libphoto2.dev
	sudo apt-get install -y libopencv-dev python-opencv
	sudo apt-get install -y libgtkmm-3.0-dev
	sudo apt-get install -y mesa-common-dev
	sudo apt-get install -y libglu1-mesa-dev libegl1-mesa-dev
	sudo apt-get install -y build-essential libfontconfig1-dev libdbus-1-dev \
	libfreetype6-dev libicu-dev libsqlite3-dev libssl-dev libpng-dev libjpeg-dev libglib2.0-dev
	sudo apt-get install -y libxcb-xinerama0-dev
	sudo apt-get install -y pkg-config-arm-linux-gnueabihf
	sudo apt-get install -y lib32z1
	sudo apt-get install -y libglfw3-dev
	sudo apt-get install -y libgles2-mesa-dev
	sudo apt-get install -y qtbase5-dev
	sudo apt-get install -y gtk2.0
    sudo apt-get install -y lib32stdc++6
    sudo apt-get build-dep -y qt5-default
    sudo apt-get install -y flex bison gperf libxslt-dev ruby
    sudo apt-get install -y libssl-dev libxcursor-dev libxcomposite-dev libxdamage-dev libxrandr-dev libcap-dev libxtst-dev \
    libpulse-dev libudev-dev libpci-dev libnss3-dev libasound2-dev libxss-dev
    sudo apt-get install -y libbz2-dev libgcrypt11-dev libdrm-dev libcups2-dev libatkmm-1.6-dev
    sudo apt-get install -y libgstreamer-plugins-base1.0-dev
    sudo apt-get install -y python2.7
#    sudo apt install -y --reinstall build-essential
    sudo apt-get install -y '^libxcb.*-dev' libx11-xcb-dev libglu1-mesa-dev libxrender-dev libxi-dev
#    sudo gcc -xc -E -v -

	sudo apt-get autoremove -y
	sudo apt-get update -y
	sudo apt-get upgrade -y
	echo "End install PC programs."

}

mountsystems()
{
	if [ $FLAGNONFS = 0 ]
	then
		echo "Mounting nfs folders..."
		sudo mount -t nfs $SERVERIP:$SERVERNFSDIR  $NFSDIR
	fi
	echo "Mounting Raspberry Pi root filesystem..."
	sudo sshfs root@$PI_IP:/ $PIROOT -o transform_symlinks -o allow_other
	echo "Mount end."
}


umountsystems()
{
	if [ $FLAGNONFS = 0 ]
	then
		echo "Unmounting nfs folders..."
		sudo umount $NFSDIR
	fi
	echo "Unmounting Raspberry Pi root filesystem"
	sudo umount $PIROOT
	echo "Unmount end."
}


make_nfs_fstab()
{
	if [ $FLAGNONFS = 1 ]
	then
		echo "Can not make NFS fstab file. NFS is disabled."
		exit
	fi
	sudo rsync -avz root@$PI_IP:/etc/fstab /home/$USERNAME
	sed -i s'/PARTUUID/#PARTUUID/' /home/$USERNAME/fstab
	echo  >> /home/$USERNAME/fstab
	echo  >> /home/$USERNAME/fstab
	echo  >> /home/$USERNAME/fstab
	echo "#**************************************************************************************************" >> /home/$USERNAME/fstab
	echo "#***************************** NFS ****************************************************************" >> /home/$USERNAME/fstab
	echo "#**************************************************************************************************" >> /home/$USERNAME/fstab
	echo "$SERVERIP:$SERVERNFSDIR/bootfs  /boot  nfs  defaults  0  0" >> /home/$USERNAME/fstab
	echo "/dev/nfs        /               rootfs  defaults          0       0" >> /home/$USERNAME/fstab
	echo "#**************************************************************************************************" >> /home/$USERNAME/fstab
	echo  >> /home/$USERNAME/fstab
	sudo ssh root@$PI_IP 'cp /etc/fstab /etc/fstab.orig'
	sudo rsync -avz /home/$USERNAME/fstab root@$PI_IP:/etc/fstab.nfs
	sudo ssh root@$PI_IP 'chown root:root /etc/fstab.nfs'
	sudo ssh root@$PI_IP 'chmod 644 /etc/fstab.nfs'
	rm /home/$USERNAME/fstab
	echo "/etc/fstab file for nfs created. The original file was saved as /etc/fstab.orig"
}

make_nfs_cmdlines()
{
	if [ $FLAGNONFS = 1 ]
	then
		echo "Can not make NFS cmdline files. NFS is disabled."
		exit
	fi
	echo "dwc_otg.lpm_enable=0 console=ttyAMA0,115200 console=tty1 root=/dev/nfs rootfstype=nfs nfsroot=$SERVERIP:$SERVERNFSDIR/rootfs,tcp,vers=3 ip=$SELF_IP:$NFS_SERVER:$ROUTER:$NETMASK:raspberrypi:eth0:off smsc95xx.turbo_mode=N elevator=deadline rootwait quiet splash plymouth.ignore-serial-consoles" > /home/$USERNAME/cmdline.nfs.staticIP
	echo >> /home/$USERNAME/cmdline.nfs.staticIP
	echo
	sudo chown root:root /home/$USERNAME/cmdline.nfs.staticIP
	sudo ssh root@$PI_IP 'mount -o remount,rw /boot'
	sudo ssh root@$PI_IP 'cp /boot/cmdline.txt /boot/cmdline.txt.orig'
	sudo rsync -avz /home/$USERNAME/cmdline.nfs.staticIP root@$PI_IP:/boot/cmdline.nfs.staticIP
	rm -f /home/$USERNAME/cmdline.nfs.staticIP

	echo "dwc_otg.lpm_enable=0 console=ttyAMA0,115200 console=tty1 root=/dev/nfs rootfstype=nfs nfsroot=$NFS_SERVER:$NFS_PATH/rootfs,tcp,vers=3 ip=dhcp smsc95xx.turbo_mode=N elevator=deadline rootwait quiet splash plymouth.ignore-serial-consoles" > /home/$USERNAME/cmdline.nfs.dhcp
	echo >> /home/$USERNAME/cmdline.nfs.dhcp
	echo
	sudo chown root:root /home/$USERNAME/cmdline.nfs.dhcp
	sudo rsync -avz /home/$USERNAME/cmdline.nfs.dhcp root@$PI_IP:/boot/cmdline.nfs.dhcp
	rm -f /home/$USERNAME/cmdline.nfs.dhcp

	echo "NFS cmdlines files generated"
}

enablenfsonpi()
{	if [ $FLAGNONFS = 1 ]
	then
		echo "Can not enable NFS on Raspberry Pi. NFS is disabled."
		exit
	fi
	echo ""
}


setpinormal()
{
	if sudo ssh root@$PI_IP_NFS '[ -d /media/pi/boot ]'
	then
		echo "Boot folder on SD: boot"
		sudo ssh root@$PI_IP_NFS 'cp /media/pi/boot/cmdline.txt.orig /media/pi/boot/cmdline.txt'
	else
		if sudo ssh root@$PI_IP_NFS '[ -d /media/pi/BOOT ]'
		then
			echo "Boot folder on SD: BOOT"
			sudo ssh root@$PI_IP_NFS 'cp /media/pi/BOOT/cmdline.txt.orig /media/pi/BOOT/cmdline.txt'
		else
			echo "Destination boot filesystem folder not found, exiting."
			exit
		fi
	fi
	sudo umount $PIROOT
	sudo ssh root@$PI_IP_NFS 'reboot'
	echo
	echo "Waiting for Pi to reboot"
	read -p "Press \"y\" when the Pi has booted completely: " prompt
	if [ $prompt = y ];
	then
		echo "OK, remounting Pi root filesystem."
	else
		echo
		echo Exiting script.
		echo
		exit
	fi
	sudo sshfs root@$PI_IP:/ $PIROOT -o transform_symlinks -o allow_other
}

setpinfs()
{
	sudo ssh root@$PI_IP 'mount -o remount,rw /boot'
	sudo ssh root@$PI_IP 'cp /boot/cmdline.nfs.staticIP /boot/cmdline.txt'
	sudo umount $PIROOT
	sudo ssh root@$PI_IP 'reboot'
	echo
	echo "Waiting for Pi to reboot"
	read -p "Press \"y\" when the Pi has booted completely: " prompt
	if [ $prompt = y ];
	then
		echo "OK, remounting Pi root filesystem."
	else
		echo
		echo Exiting script.
		echo
		exit
	fi
	sudo sshfs root@$PI_IP_NFS:/ $PIROOT -o transform_symlinks -o allow_other
}



copyLocalRootPubkeyToServer()
{
	if sudo test -f "/root/.ssh/id_rsa.pub";
	then
		echo "Found root ssh public key..."
	else
		echo
		echo "Can not find root ssh public key (/root/.ssh/id_rsa.pub)."
		echo "To create root rsa keypair run:"
		echo
		echo "sudo ssh-keygen"
		echo
		echo "Exiting script."
		echo
		exit
	fi
	sudo cp /root/.ssh/id_rsa.pub /home/$USERNAME
	sudo ssh-keygen -f "/root/.ssh/known_hosts" -R "$SERVERIP"
	ssh-keygen -f "/home/$USERNAME/.ssh/known_hosts" -R "$SERVERIP"
    echo "if [ ! -d /root/.ssh ]" > /home/$USERNAME/erl
    echo "then" >> /home/$USERNAME/erl
    echo "mkdir /root/.ssh" >> /home/$USERNAME/erl
    echo "fi" >> /home/$USERNAME/erl
    echo "if test -f \"/root/.ssh/authorized_keys\";" >> /home/$USERNAME/erl
    echo "then" >> /home/$USERNAME/erl
    echo "sed -i ':a;N;$!ba;s#.* root@$HOSTNAME\n##' /root/.ssh/authorized_keys" >> /home/$USERNAME/erl
    echo "fi" >> /home/$USERNAME/erl
    echo "cat id_rsa.pub >> /root/.ssh/authorized_keys" >> /home/$USERNAME/erl
    echo "if test -f \"/root/.ssh/known_hosts\";" >> /home/$USERNAME/erl
    echo "then" >> /home/$USERNAME/erl
    echo "ssh-keygen -f \"/root/.ssh/known_hosts\" -R \"$OWNIP\"" >> /home/$USERNAME/erl
    echo "ssh-keygen -f \"/root/.ssh/known_hosts\" -R \"$HOSTNAME\"" >> /home/$USERNAME/erl
    echo "fi" >> /home/$USERNAME/erl
	chmod 775 /home/$USERNAME/erl
	rsync -avz /home/$USERNAME/id_rsa.pub /home/$USERNAME/erl $SERVERLOGIN:/home/$SERVERUSERNAME
	echo
	echo "**********************************************************************************"
	echo "You will be prompted for user password on server and you will be transferred to server terminal."
	echo "On server, become superuser and execute ./erl command."
	echo "Once you see the server prompt ($SERVERUSERNAME@<server name>:~ $ ), type the following commands:"
	echo
	echo "su"
	echo "Input the root password..."
	echo "The prompt will change to root@<server name>:/home/$SERVERUSERNAME#"
	echo
	echo "Then type:"
	echo "./erl"
	echo "exit"
	echo "exit"
	echo "**********************************************************************************"
	echo
	ssh $SERVERLOGIN
	echo "**********************************************************************************"
	echo Cleaning...
	echo "**********************************************************************************"
	sudo ssh root@$SERVERIP 'chown root:root /root/.ssh/authorized_keys'
	sudo ssh root@$SERVERIP 'chmod 600 /root/.ssh/authorized_keys'
	sudo ssh root@$SERVERIP 'rm /home/'$SERVERUSERNAME'/erl'
	sudo ssh root@$SERVERIP 'rm -f /home/'$SERVERUSERNAME'/id_rsa.pub'
	rm /home/$USERNAME/erl
	rm -f /home/$USERNAME/id_rsa.pub
	echo "Done. You can login withou password to Pi root account."
	echo "Type sudo ssh root@$SERVERIP"
	echo
}


copyLocalRootPubkeyToPi()
{
	if sudo test -f "/root/.ssh/id_rsa.pub";
	then
		echo "Found root ssh public key..."
	else
		echo
		echo "Can not find root ssh public key (/root/.ssh/id_rsa.pub)."
		echo "To create root rsa keypair run:"
		echo
		echo "sudo ssh-keygen"
		echo
		echo "Exiting script."
		echo
		exit
	fi
	sudo cp /root/.ssh/id_rsa.pub /home/$USERNAME
	sudo ssh-keygen -f "/root/.ssh/known_hosts" -R "$PI_IP"
	ssh-keygen -f "/home/$USERNAME/.ssh/known_hosts" -R "$PI_IP"
    echo "if [ ! -d /root/.ssh ]" > /home/$USERNAME/erl
    echo "then" >> /home/$USERNAME/erl
    echo "mkdir /root/.ssh" >> /home/$USERNAME/erl
    echo "fi" >> /home/$USERNAME/erl
    echo "if test -f \"/root/.ssh/authorized_keys\";" >> /home/$USERNAME/erl
    echo "then" >> /home/$USERNAME/erl
    echo "sed -i ':a;N;$!ba;s#.* root@$HOSTNAME\n##' /root/.ssh/authorized_keys" >> /home/$USERNAME/erl
    echo "fi" >> /home/$USERNAME/erl
    echo "cat id_rsa.pub >> /root/.ssh/authorized_keys" >> /home/$USERNAME/erl
    echo "if test -f \"/root/.ssh/known_hosts\";" >> /home/$USERNAME/erl
    echo "then" >> /home/$USERNAME/erl
    echo "ssh-keygen -f \"/root/.ssh/known_hosts\" -R \"$OWNIP\"" >> /home/$USERNAME/erl
    echo "ssh-keygen -f \"/root/.ssh/known_hosts\" -R \"$HOSTNAME\"" >> /home/$USERNAME/erl
    echo "fi" >> /home/$USERNAME/erl

	echo "sed -i \"s/AcceptEnv LANG LC_\*/#AcceptEnv LANG LC_\*/g\" /etc/ssh/sshd_config" >> /home/$USERNAME/erl
	echo "systemctl restart ssh.service" >> /home/$USERNAME/erl

	chmod 775 /home/$USERNAME/erl
	rsync -avz /home/$USERNAME/id_rsa.pub /home/$USERNAME/erl $RPILOGIN:/home/$PIUSERNAME
	echo
	echo "**********************************************************************************"
	echo "You will be prompted for the pi password again and you will be transferred to Pi terminal."
	echo "Once you see the pi prompt ($PIUSERNAME@raspberrypi:~ $ ), type the following commands:"
	echo
	echo "sudo ./erl"
	echo "exit"
	echo "**********************************************************************************"
	echo
	ssh $RPILOGIN
	echo "**********************************************************************************"
	echo Cleaning...
	echo "**********************************************************************************"
	sudo ssh root@$PI_IP 'chown root:root /root/.ssh/authorized_keys'
	sudo ssh root@$PI_IP 'chmod 600 /root/.ssh/authorized_keys'
	sudo ssh root@$PI_IP 'rm /home/'$PIUSERNAME'/erl'
	sudo ssh root@$PI_IP 'rm -f /home/'$PIUSERNAME'/id_rsa.pub'
	rm /home/$USERNAME/erl
	rm -f /home/$USERNAME/id_rsa.pub
	echo "Done. You can login withou password to Pi root account."
	echo "Type sudo ssh root@$PI_IP"
	echo
}

syncsystems()
{
	if [ ! -z "$1" ]
	then
		FUNCPARAM=$1
	fi
 	case $FUNCPARAM in
 	local)
		echo "Suncing filesystems. Master = local filesystem"
		if [ -z "$(ls -A $SYSROOT)" ];
		then
			echo "local sysroot folder is empty, abandoning sync."
			exit
		fi
		if [ $FLAGNONFS = 0 ]
		then
			sudo rsync -avxHAXz --delete --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found/*} $SYSROOT/ root@$SERVERIP:$SERVERNFSROOT
#			setpinfs
#			sudo rsync -avxHAXz --delete --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found/*} $SYSROOT/ $PIROOT/media/$PIUSERNAME/rootfs
			sudo rsync -avxHAXz --delete --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found/*} $SYSROOT/ $PIROOT
#			setpinormal
		else
			sudo rsync -avxHAXz --delete --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found/*} $SYSROOT/ $PIROOT
		fi
	;;
	nfs)
		if [ $FLAGNONFS = 1 ]
		then
			echo "NFS is absent. Can not sync non existing system."
			exit
		fi
		echo "Suncing filesystems. Master = NFS filesystem"
		if [ -z "$(ls -A $NFSROOT)" ];
		then
			echo "nfs sysroot folder is empty, abandoning sync."
			exit
		fi
		sudo rsync -avxHAXz --delete --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found/*} root@$SERVERIP:$SERVERNFSROOT/ $SYSROOT
#		setpinfs
#		sudo rsync -avxHAXz --delete --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found/*} $SYSROOT/ $PIROOT/media/$PIUSERNAME/rootfs
		sudo rsync -avxHAXz --delete --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found/*} $SYSROOT/ $PIROOT
#		setpinormal
	;;
	pi)
		echo "Suncing filesystems. Master = Raspberry Pi filesystem"
		if [ -z "$(ls -A $PIROOT)" ];
		then
			echo "pi sysroot folder is empty, abandoning sync."
			exit
		fi
		if [ $FLAGNONFS = 0 ]
		then
#			setpinfs
#			sudo rsync -avxHAXz --delete --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found/*} $PIROOT/media/$PIUSERNAME/rootfs/ $SYSROOT
			sudo rsync -avxHAXz --delete --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found/*} $PIROOT/ $SYSROOT
#			setpinormal
			sudo rsync -avxHAXz --delete --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found/*} $SYSROOT/ root@$SERVERIP:$SERVERNFSROOT
		else
			sudo rsync -avxHAXz --delete --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found/*} $PIROOT/ $SYSROOT
		fi
	;;
	*)
		echo "syncsystems - invalid option! Chose: < local | nfs| pi >"
	;;
	esac
}


installtrust()
{
	if [ $FLAGNONFS = 0 ]
	then
		copyLocalRootPubkeyToServer
	fi
	copyLocalRootPubkeyToPi
}

updatepi()
{

	echo "Optional - Midnight Commander installation."
	sudo ssh root@$PI_IP 'apt-get install -y mc'
	sudo ssh root@$PI_IP 'rm -rf /boot.bak'
	echo "Delete LibreOffice and Wolfram (for sparing space on SD and quicker syncs)?"
	echo "Do you want to delete the mentioned packages?"
	read -p "y-delete both; l-delete LibreOffice; w-delete Wolfram; n-delete none < y | l | w | n >: " prompt
	case "$prompt" in
	y)
		echo "Deleting LibreOffice and Wolfram..."
		sudo ssh root@$PI_IP 'apt-get purge -y libreoffice*'
		sudo ssh root@$PI_IP 'apt-get purge -y wolfram-engine'
	;;
	l)
		echo "Deleting LibreOffice..."
		sudo ssh root@$PI_IP 'apt-get purge -y libreoffice*'
	;;
	w)
		echo "Deleting Wolfram..."
		ssudo ssh root@$PI_IP 'apt-get purge -y libreoffice*'
	;;
	esac
	sudo ssh root@$PI_IP 'apt-get clean -y'
	sudo ssh root@$PI_IP 'apt-get autoremove -y'
	sudo ssh root@$PI_IP 'apt-get -y update'
	sudo ssh root@$PI_IP 'apt-get -y upgrade'
}


installpiqtprogs()
{
	#######################################################
	#                  Qt
	#######################################################

echo "**************************************************************************"
echo "**************************************************************************"
echo "         Installing packages for Qt"
echo "**************************************************************************"
echo "**************************************************************************"
echo "Enabling sources repo"
echo "**************************************************************************"
sudo ssh root@$PI_IP 'sed -i 's/#deb-src/deb-src/' /etc/apt/sources.list'
echo "**************************************************************************"
echo "Update"
echo "**************************************************************************"
sudo ssh root@$PI_IP 'apt-get update'
echo "**************************************************************************"
echo "Install dependencies for qt4-x11"
echo "**************************************************************************"
sudo ssh root@$PI_IP 'apt-get build-dep qt4-x11 -y'
echo "**************************************************************************"
echo "Install dependencies for libqt5gui5"
echo "**************************************************************************"
sudo ssh root@$PI_IP 'apt-get build-dep -y libqt5gui5 -y'
echo "**************************************************************************"
echo "Install libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0"
echo "**************************************************************************"
sudo ssh root@$PI_IP 'apt-get install -y libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0'
echo "**************************************************************************"
echo "Build tools"
echo "**************************************************************************"
sudo ssh root@$PI_IP 'apt-get install -y build-essential cmake pkg-config' #OpenCV

echo "**************************************************************************"
echo "GUI (if you want to use GTK instead of Qt, replace 'qt5-default' with 'libgtkglext1-dev' and remove '-DWITH_QT=ON' option in CMake)"
echo "**************************************************************************"
sudo ssh root@$PI_IP 'apt-get install -y qt5-default libvtk6-dev'
echo "**************************************************************************"
echo " Media I/O:"
echo "**************************************************************************"
sudo ssh root@$PI_IP 'apt-get install -y zlib1g-dev libjpeg-dev libwebp-dev libpng-dev libpng12-dev libtiff5-dev libjasper-dev libopenexr-dev libgdal-dev'
echo "**************************************************************************"
echo "Video I/O"
echo "**************************************************************************"
sudo ssh root@$PI_IP 'apt-get install -y libdc1394-22-dev libavcodec-dev libavformat-dev libswscale-dev libtheora-dev libvorbis-dev libxvidcore-dev libx264-dev yasm libopencore-amrnb-dev libopencore-amrwb-dev libv4l-dev libxine2-dev v4l-utils'
echo "**************************************************************************"
echo "Parallelism and linear algebra libraries"
echo "**************************************************************************"
sudo ssh root@$PI_IP 'apt-get install -y libtbb-dev libeigen3-dev'
echo "**************************************************************************"
echo "Python"
echo "**************************************************************************"
sudo ssh root@$PI_IP 'apt-get install -y python-dev python-tk python-numpy python2.7-dev python3-dev python3-dev python3-tk python2-numpy python3-numpy'
echo "**************************************************************************"
#echo "Java"
#echo "**************************************************************************"
#sudo ssh root@$PI_IP 'apt-get install -y ant default-jdk'
#sudo apt-get remove -y openjdk-8-jre-headless openjdk-8-jre
#sudo apt-get install -y ca-certificates-java
#sudo apt-get install -y openjdk-8-jre-headless
#sudo apt-get instal -y openjdk-8-jre
#echo "**************************************************************************"
#echo "OpenGL ES 3 support ???"
#echo "**************************************************************************"
#sudo apt-get install -y libglfw3-dev libgles2-mesa-dev
#sudo apt autoremove
#echo "**************************************************************************"
echo "Documentation"
echo "**************************************************************************"
sudo ssh root@$PI_IP 'apt-get install -y doxygen'

#sudo ssh root@$PI_IP 'apt-get install -y libatlas-base-dev gfortran' #OpenCV
#sudo ssh root@$PI_IP 'apt-get install -y libgtk2.0-dev' #OpenCV
#sudo ssh root@$PI_IP 'apt-get install -y libraspberrypi-dev' #???

echo "**************************************************************************"
echo "**************************************************************************"
echo "                   Pi install - End of Qt section"
echo "**************************************************************************"
echo "**************************************************************************"
echo
}



installpiopencvprogs()
{
	#######################################################
	#                  OpenCV
	#######################################################

echo "**************************************************************************"
echo "**************************************************************************"
echo "         Installing packages for OpenCV"
echo "**************************************************************************"
echo "**************************************************************************"
#echo "libjpeg-dev libtiff5-dev libjasper-dev libpng12-dev"
#echo "**************************************************************************"
#sudo ssh root@$PI_IP 'apt-get install -y libjpeg-dev libtiff5-dev libjasper-dev libpng12-dev'
#echo "**************************************************************************"
#echo "libavcodec-dev libavformat-dev libswscale-dev libv4l-dev"
#echo "**************************************************************************"
#sudo ssh root@$PI_IP 'apt-get install -y libavcodec-dev libavformat-dev libswscale-dev libv4l-dev'
#echo "**************************************************************************"
#echo "libxvidcore-dev libx264-dev libeigen3-dev v4l-utils"
#echo "**************************************************************************"
#sudo ssh root@$PI_IP 'apt-get install -y libxvidcore-dev libx264-dev libeigen3-dev v4l-utils'
#echo "**************************************************************************"
echo "libgtk3.0-dev"
echo "**************************************************************************"
#sudo ssh root@$PI_IP 'apt-get install -y libgtk2.0-dev'
sudo ssh root@$PI_IP 'apt-get install -y libgtk-3-dev '
echo "**************************************************************************"
echo "libatlas-base-dev gfortran ffmpeg"
echo "**************************************************************************"
sudo ssh root@$PI_IP 'apt-get install -y libatlas-base-dev gfortran ffmpeg'
#echo "**************************************************************************"
#echo "python2.7-dev python3-dev python2-numpy python3-numpy"
#echo "**************************************************************************"
#sudo ssh root@$PI_IP 'apt-get install -y python2.7-dev python3-dev python2-numpy python3-numpy'
echo "**************************************************************************"
echo "**************************************************************************"
echo "                   Pi install - End of OpenCV section"
echo "**************************************************************************"
echo "**************************************************************************"
}


installpigphoto2progs()
{
	#######################################################
	#                  gphoto2
	#######################################################

echo "**************************************************************************"
echo "**************************************************************************"
echo "         Installing packages for gphoto2"
echo "**************************************************************************"
	sudo ssh root@$PI_IP 'apt-get install -y htop'
	sudo ssh root@$PI_IP 'apt-get install -y libltdl-dev'
	sudo ssh root@$PI_IP 'apt-get install -y libexif-dev'
###	sudo ssh root@$PI_IP 'apt-get install -y libturbojpeg1-dev' #???
	sudo ssh root@$PI_IP 'apt-get install -y libusb-dev'
	sudo ssh root@$PI_IP 'apt-get install -y libusb-1.0-0-dev'
	sudo ssh root@$PI_IP 'apt-get install -y gdb-multiarch'
	sudo ssh root@$PI_IP 'apt-get install -y xkb-data console-data'
	sudo ssh root@$PI_IP 'apt-get install -y gphoto2'
	sudo ssh root@$PI_IP 'apt-get install -y libpopt-dev'
echo "**************************************************************************"
echo "**************************************************************************"
echo "              Pi install - End of gphoto2 section"
echo "**************************************************************************"
echo "**************************************************************************"
}

installpiprogs()
{
	updatepi
	installpiqtprogs
	installpiopencvprogs
	installpigphoto2progs
	echo "**************************************************************************"
	echo "                         Final update"
	echo "**************************************************************************"
	echo "**************************************************************************"
	sudo ssh root@$PI_IP 'apt-get autoremove -y'
	sudo ssh root@$PI_IP 'apt-get -y update'
	sudo ssh root@$PI_IP 'apt-get -y upgrade'
	echo "**************************************************************************"
	echo "**************************************************************************"
	echo "                        Pi install - End"
	echo "**************************************************************************"
	echo "**************************************************************************"
}

fetchdata()
{
	###############################################
	#                       Qt
	###############################################
	cd $WORKDIR
	git clone https://github.com/raspberrypi/tools
	wget https://raw.githubusercontent.com/riscv/riscv-poky/priv-1.10/scripts/sysroot-relativelinks.py
	chmod +x sysroot-relativelinks.py
	mkdir $QTDIR
	cd $QTDIR
	git clone git://code.qt.io/qt/qtbase.git -b $QTVERSION

	###############################################
	#                     OpenCV
	###############################################
	echo "**************************************************************************"
	echo "**************************************************************************"
	echo "Fetch and unzip OpenCV"
	echo "**************************************************************************"
	cd $WORKDIR
	wget -O opencv.zip https://github.com/Itseez/opencv/archive/$OPENCV_VERSION.zip
	unzip opencv.zip
	echo "**************************************************************************"
	echo "Fetch and unzip OpenCV-contrib"
	echo "**************************************************************************"
	wget -O opencv_contrib.zip https://github.com/Itseez/opencv_contrib/archive/$OPENCV_VERSION.zip
	unzip opencv_contrib.zip
	echo
	echo "**************************************************************************"

	###############################################
	#                    gphoto2
	###############################################
	echo "**************************************************************************"
	echo "**************************************************************************"
	echo "Fetch and unzip libgphoto2"
	echo "**************************************************************************"
	wget -O libgphoto2.tar.bz2 https://sourceforge.net/projects/gphoto/files/libgphoto/$LIBGPHOTO2_VERSION/libgphoto2-$LIBGPHOTO2_VERSION.tar.bz2/download
	tar -jxvf libgphoto2.tar.bz2
	#echo "**************************************************************************"
	#echo "Fetch and unzip libusb"
	#echo "**************************************************************************"
	#wget -O libusb.tar.bz2 https://sourceforge.net/projects/libusb/files/libusb-1.0/libusb-1.0.21/libusb-1.0.21.tar.bz2/download
	#tar -jxvf libusb.tar.bz2
	echo "**************************************************************************"

	###############################################
	#                    wiringPi
	###############################################
	echo "**************************************************************************"
	echo "**************************************************************************"
	echo "Fetch and unzip wiringpi"
	echo "**************************************************************************"
	wget -O wiringpi.tgz "https://git.drogon.net/?p=wiringPi;a=snapshot;h=$WIRNIGPICOMMIT;sf=tgz"
	tar -zxvf wiringpi.tgz
	echo "**************************************************************************"
}

exportpaths()
{
	export PKG_CONFIG_SYSROOT_DIR=$SYSROOT
#	export PKG_CONFIG_PATH=/usr/share/arm-linux-gnueabihf/pkgconfig:$SYSROOT/usr/lib/pkgconfig
	export PKG_CONFIG_PATH=/usr/share/arm-linux-gnueabihf/pkgconfig:$SYSROOT/usr/lib/pkgconfig:$SYSROOT/usr/share/pkgconfig:$SYSROOT/usr/lib/arm-linux-gnueabihf/pkgconfig:$SYSROOT/opt/vc/lib/pkgconfig

}

removesymlinks()
{
    sudo rm -rf /lib/arm-linux-gnueabihf
	sudo rm -rf /usr/lib/arm-linux-gnueabihf
	sudo rm -rf /usr/share/arm-linux-gnueabihf
	sudo rm -rf /usr/include/arm-linux-gnueabihf
}

makesymlinks()
{
	removesymlinks
	sudo ln -s $SYSROOT/lib/arm-linux-gnueabihf/ /lib/arm-linux-gnueabihf
	sudo ln -s $SYSROOT/usr/lib/arm-linux-gnueabihf/ /usr/lib/arm-linux-gnueabihf
	sudo ln -s $SYSROOT/usr/share /usr/share/arm-linux-gnueabihf
	sudo ln -s $SYSROOT/usr/include/arm-linux-gnueabihf /usr/include/arm-linux-gnueabihf

	exportpaths

	echo "*********************************************************"
    arm-linux-gnueabihf-pkg-config --libs gtk+-2.0
    arm-linux-gnueabihf-pkg-config --cflags gtk+-2.0
	echo "*********************************************************"
    arm-linux-gnueabihf-pkg-config --libs gtk+-3.0
    arm-linux-gnueabihf-pkg-config --cflags gtk+-3.0
	echo "*********************************************************"
}

makepkgconfigsymlinkstemplate()
{
	if [ -f $2/$1 ]
	then
		if [ -f $2/$1.bak ]
		then
			sudo rm $2/$1
		else
			sudo mv $2/$1 $2/$1.bak
		fi
		sudo ln -rsf $3/opt/vc/lib/pkgconfig/$1 $2/$1
	else
		DEFAULTFOLDER=$SYSROOT/usr/lib/pkgconfig
		if [[ "$2" == "$DEFAULTFOLDER" ]]
		then # make anyway symlinks in /usr/lib/pkgconfig
			sudo ln -rsf $3/opt/vc/lib/pkgconfig/$1 $2/$1
		fi
	fi
}


makepkgconfigsymlinks()
{
	makepkgconfigsymlinkstemplate bcm_host.pc $1 $2
	makepkgconfigsymlinkstemplate brcmegl.pc $1 $2
	makepkgconfigsymlinkstemplate brcmglesv2.pc $1 $2
	makepkgconfigsymlinkstemplate brcmvg.pc $1 $2
	makepkgconfigsymlinkstemplate egl.pc $1 $2
	makepkgconfigsymlinkstemplate glesv2.pc $1 $2
	makepkgconfigsymlinkstemplate mmal.pc $1 $2
	makepkgconfigsymlinkstemplate vcsm.pc $1 $2
	makepkgconfigsymlinkstemplate vg.pc $1 $2
}


removeredundantpkgconfig()
{
	# Build with pkgconfig files from /opt/vc/lib/pkgconfig and
	# remove the other redundant pkgconfig files
	# pkgconfig paths:
	# /usr/lib/pkgconfig
	# /usr/lib/arm-linux-gnueabihf/pkgconfig
	# /usr/local/lib/pkgconfig
	# /usr/local/share/pkgconfig
	# /usr/share/pkgconfig
	makepkgconfigsymlinks $SYSROOT/usr/lib/pkgconfig ../../..
	makepkgconfigsymlinks $SYSROOT/usr/lib/arm-linux-gnueabihf/pkgconfig ../../../..
	makepkgconfigsymlinks $SYSROOT/usr/local/lib/pkgconfig ../../../..
	makepkgconfigsymlinks $SYSROOT/usr/local/share/pkgconfig ../../../..
	makepkgconfigsymlinks $SYSROOT/usr/share/pkgconfig ../../..
	makepkgconfigsymlinks $PIROOT/usr/lib/pkgconfig ../../..
	makepkgconfigsymlinks $PIROOT/usr/lib/arm-linux-gnueabihf/pkgconfig ../../../..
	makepkgconfigsymlinks $PIROOT/usr/local/lib/pkgconfig ../../../..
	makepkgconfigsymlinks $PIROOT/usr/local/share/pkgconfig ../../../..
	makepkgconfigsymlinks $PIROOT/usr/share/pkgconfig ../../..
}



buildqt()
{
	if [ ! -z "$1" ]
	then
		FUNCPARAM=$1
	fi
 	case $FUNCPARAM in
	configure)
		echo "Configuring Qt..."
		removeredundantpkgconfig
		cd $QTDIR/qtbase
		./configure -release \
		-opengl es2 \
		-device linux-rasp-pi3-g++ \
		-device-option CROSS_COMPILE=/usr/bin/arm-linux-gnueabihf- \
		-sysroot $SYSROOT \
		-opensource \
		-confirm-license \
		-make libs \
		-prefix /usr/local/qt5pi \
		-extprefix $CROSS_BUILT/$QTCOMPILEDVERSION_PI \
		-hostprefix $CROSS_BUILT/$QTCOMPILEDVERSION_PC \
		-no-use-gold-linker \
		-v \
		|& tee $LOGDIR/configureqt.log
		echo "End configure Qt."
		
#-eglfs \
#-qt-xcb \
#-opengl desktop \
#-device linux-rasp-pi3-vc4-g++
#-device linux-rasp-pi*-g++
#-force-pkg-config \
#-nomake examples \
#-no-compile-examples \
#-skip qtwayland \
#-skip qtwebengine \
#-release \
#-qt-pcre \
#-ssl \
#-evdev \
#-system-freetype \
#-fontconfig \
#-glib \

	;;
	build)
		echo "Building Qt..."
		cd $QTDIR/qtbase
		make -j$CPUCORES |& tee $LOGDIR/makeqt.log
		make install -j$CPUCORES |& tee $LOGDIR/makeinstallqt.log
		echo "end build Qt."
	;;
	clean)
		echo "Cleaning Qt..."
		cd $QTDIR/qtbase
		make clean -j$CPUCORES
		git clean -dfx
		sudo rm -rf $CROSS_BUILT/$QTCOMPILEDVERSION_PI
		rm -rf $CROSS_BUILT/$QTCOMPILEDVERSION_PC
		sudo rm -rf $PIROOT/usr/local/$QTCOMPILEDVERSION_PI
		sudo rm -f $PIROOT/etc/ld.so.conf.d/$QTCOMPILEDVERSION_PI.conf
		if [ -f $PIROOT/usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0_backup ]
		then
			mv $PIROOT/usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0_backup $PIROOT/usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0
		else
			echo "File $PIROOT/usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0_backup does not exist."
		fi
		if [ -f $PIROOT/usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0_backup ]
		then
			mv $PIROOT/usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0_backup $PIROOT/usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0
		else
			echo "File $PIROOT/usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0_backup does not exist."
		fi
		echo "End clean Qt"
	;;
	deploy)
		echo "Deploying Qt..."
#		echo "Making Qt folder on Raspberry Pi"
#		sudo ssh root@$PI_IP 'sudo mkdir /usr/local/qt5pi'
#		sudo ssh root@$PI_IP 'sudo chown pi:pi /usr/local/qt5pi'
		sudo chown -R root:root $CROSS_BUILT/$QTCOMPILEDVERSION_PI
		sudo rsync -avz --delete $CROSS_BUILT/$QTCOMPILEDVERSION_PI $PIROOT/usr/local
		#         Fix prefixes in pkgconfig files on Pi
		sudo sed -i 's|prefix='$CROSS_BUILT'/'$QTCOMPILEDVERSION_PI'|prefix=/usr/local/'$QTCOMPILEDVERSION_PI'|' $PIROOT/usr/local/$QTCOMPILEDVERSION_PI/lib/pkgconfig/Qt5Concurrent.pc
		sudo sed -i 's|prefix='$CROSS_BUILT'/'$QTCOMPILEDVERSION_PI'|prefix=/usr/local/'$QTCOMPILEDVERSION_PI'|' $PIROOT/usr/local/$QTCOMPILEDVERSION_PI/lib/pkgconfig/Qt5Core.pc
		sudo sed -i 's|prefix='$CROSS_BUILT'/'$QTCOMPILEDVERSION_PI'|prefix=/usr/local/'$QTCOMPILEDVERSION_PI'|' $PIROOT/usr/local/$QTCOMPILEDVERSION_PI/lib/pkgconfig/Qt5DBus.pc
		sudo sed -i 's|prefix='$CROSS_BUILT'/'$QTCOMPILEDVERSION_PI'|prefix=/usr/local/'$QTCOMPILEDVERSION_PI'|' $PIROOT/usr/local/$QTCOMPILEDVERSION_PI/lib/pkgconfig/Qt5Gui.pc
		sudo sed -i 's|prefix='$CROSS_BUILT'/'$QTCOMPILEDVERSION_PI'|prefix=/usr/local/'$QTCOMPILEDVERSION_PI'|' $PIROOT/usr/local/$QTCOMPILEDVERSION_PI/lib/pkgconfig/Qt5Network.pc
		sudo sed -i 's|prefix='$CROSS_BUILT'/'$QTCOMPILEDVERSION_PI'|prefix=/usr/local/'$QTCOMPILEDVERSION_PI'|' $PIROOT/usr/local/$QTCOMPILEDVERSION_PI/lib/pkgconfig/Qt5OpenGL.pc
		sudo sed -i 's|prefix='$CROSS_BUILT'/'$QTCOMPILEDVERSION_PI'|prefix=/usr/local/'$QTCOMPILEDVERSION_PI'|' $PIROOT/usr/local/$QTCOMPILEDVERSION_PI/lib/pkgconfig/Qt5OpenGLExtensions.pc
		sudo sed -i 's|prefix='$CROSS_BUILT'/'$QTCOMPILEDVERSION_PI'|prefix=/usr/local/'$QTCOMPILEDVERSION_PI'|' $PIROOT/usr/local/$QTCOMPILEDVERSION_PI/lib/pkgconfig/Qt5PrintSupport.pc
		sudo sed -i 's|prefix='$CROSS_BUILT'/'$QTCOMPILEDVERSION_PI'|prefix=/usr/local/'$QTCOMPILEDVERSION_PI'|' $PIROOT/usr/local/$QTCOMPILEDVERSION_PI/lib/pkgconfig/Qt5Sql.pc
		sudo sed -i 's|prefix='$CROSS_BUILT'/'$QTCOMPILEDVERSION_PI'|prefix=/usr/local/'$QTCOMPILEDVERSION_PI'|' $PIROOT/usr/local/$QTCOMPILEDVERSION_PI/lib/pkgconfig/Qt5Test.pc
		sudo sed -i 's|prefix='$CROSS_BUILT'/'$QTCOMPILEDVERSION_PI'|prefix=/usr/local/'$QTCOMPILEDVERSION_PI'|' $PIROOT/usr/local/$QTCOMPILEDVERSION_PI/lib/pkgconfig/Qt5Widgets.pc
		sudo sed -i 's|prefix='$CROSS_BUILT'/'$QTCOMPILEDVERSION_PI'|prefix=/usr/local/'$QTCOMPILEDVERSION_PI'|' $PIROOT/usr/local/$QTCOMPILEDVERSION_PI/lib/pkgconfig/Qt5Xml.pc

		# Fix raspbian OpenGL ES library usage
		sudo ssh root@$PI_IP 'echo /usr/local/'$QTCOMPILEDVERSION_PI'/lib | sudo tee /etc/ld.so.conf.d/'$QTCOMPILEDVERSION_PI'.conf'
		sudo ssh root@$PI_IP 'ldconfig'
		if [ -f $PIROOT/usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0_backup ]
		then
			echo "File $PIROOT/usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0_backup already exists."
		else
			mv $PIROOT/usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0 $PIROOT/usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0_backup
		fi
		if [ -f $PIROOT/usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0_backup ]
		then
			echo "File $PIROOT/usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0_backup already exists."
		else
			mv $PIROOT/usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0 $PIROOT/usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0_backup
		fi
		sudo ssh root@$PI_IP 'ln -rsf /opt/vc/lib/libEGL.so /usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0'
		sudo ssh root@$PI_IP 'ln -rsf /opt/vc/lib/libGLESv2.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0'
		sudo ssh root@$PI_IP 'ln -rsf /opt/vc/lib/libEGL.so /opt/vc/lib/libEGL.so.1'
		sudo ssh root@$PI_IP 'ln -rsf /opt/vc/lib/libGLESv2.so /opt/vc/lib/libGLESv2.so.2'
		echo "End deploy QT."
	;;
	*)
		echo "buildqt - invalid option! Valid options are: configure, build, deploy, clean"
	;;
	esac
}

buildopencv()
{
	if [ ! -z "$1" ]
	then
		FUNCPARAM=$1
	fi
 	case $FUNCPARAM in
	configure)
		echo "Configuring OpenCV..."
		removesymlinks
		makesymlinks
		cd $WORKDIR
		./sysroot-relativelinks.py $SYSROOT
		cp opencv-$OPENCV_VERSION/platforms/linux/arm-gnueabi.toolchain.cmake buffer
		echo "set(ENV{PKG_CONFIG_PATH} \"/usr/share/arm-linux-gnueabihf/pkgconfig:$SYSROOT/usr/lib/pkgconfig\")" \
		> opencv-$OPENCV_VERSION/platforms/linux/arm-gnueabi.toolchain.cmake
		echo "set(ENV{PKG_CONFIG_SYSROOT_DIR} \"$SYSROOT\")" \
		>> opencv-$OPENCV_VERSION/platforms/linux/arm-gnueabi.toolchain.cmake
		echo "set(PKG_CONFIG_EXECUTABLE \"/usr/bin/arm-linux-gnueabihf-pkg-config\")" \
		>> opencv-$OPENCV_VERSION/platforms/linux/arm-gnueabi.toolchain.cmake
		echo "set(ENV{LD_LIBRARY_PATH} \"$SYSROOT/usr/lib\")" \
		>> opencv-$OPENCV_VERSION/platforms/linux/arm-gnueabi.toolchain.cmake
		echo "set(ENV{C_INCLUDE_PATH} \"$SYSROOT/usr/include\")" \
		>> opencv-$OPENCV_VERSION/platforms/linux/arm-gnueabi.toolchain.cmake
		echo "set(ENV{CPLUS_INCLUDE_PATH} \"$SYSROOT/usr/include\")" \
		>> opencv-$OPENCV_VERSION/platforms/linux/arm-gnueabi.toolchain.cmake
		cat buffer >> opencv-$OPENCV_VERSION/platforms/linux/arm-gnueabi.toolchain.cmake
		rm buffer

		cd $WORKDIR/opencv-$OPENCV_VERSION
		mkdir build
		cd build
		cmake -D CMAKE_BUILD_TYPE=RELEASE \
		-D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-$OPENCV_VERSION/modules \
		-D ENABLE_NEON=ON \
		-D ENABLE_VFPV3=ON \
		-D BUILD_TESTS=OFF \
		-D INSTALL_PYTHON_EXAMPLES=OFF \
		-D BUILD_EXAMPLES=OFF \
		-D CMAKE_TOOLCHAIN_FILE=../platforms/linux/arm-gnueabi.toolchain.cmake \
		-D WITH_OPENGL=ON \
		.. |& tee $LOGDIR/configureopencv.log

#		-D WITH_TBB=ON \
#		-D BUILD_TBB=ON \
#		-D WITH_GPHOTO2=ON \
#		-D WITH_QT=ON \
#		-D ENABLE_PRECOMPILED_HEADERS=OFF \
#		-D WITH_1394=OFF \

		echo "End configure OpenCV."
	;;
	build)
		echo "Building OpenCV..."
		cd $WORKDIR/opencv-$OPENCV_VERSION/build
		make -j$CPUCORES |& tee $LOGDIR/makeopencv.log
		make install -j$CPUCORES |& tee $LOGDIR/makeinstallopencv.log
		echo "End build OpenCV."
	;;
	clean)
		echo "Cleaning OpenCV..."
#		rm -rf $WORKDIR/opencv-$OPENCV_VERSION/build
		rm -f $CROSS_BUILT/local/bin/opencv*
		rm -rf $CROSS_BUILT/local/include/opencv
		rm -rf $CROSS_BUILT/local/include/opencv2
		rm -f $CROSS_BUILT/local/lib/libopencv*
		rm -f $CROSS_BUILT/local/lib/libtbb*
		rm -f $CROSS_BUILT/local/lib/pkgconfig/opencv*
		rm -rf $CROSS_BUILT/local/share/OpenCV

		sudo rm -f $PIROOT/usr/local/bin/opencv*
		sudo rm -rf $PIROOT/usr/local/include/opencv
		sudo rm -rf $PIROOT/usr/local/include/opencv2
		sudo rm -f $PIROOT/usr/local/lib/libopencv*
		sudo rm -f $PIROOT/usr/local/lib/libtbb*
		sudo rm -f $PIROOT/usr/local/lib/pkgconfig/opencv*
		sudo rm -rf $PIROOT/usr/local/share/OpenCV
		echo "End clean OpenCV."
	;;
	deploy)
		echo "Deploying OpenCV..."
#		cp -r $WORKDIR/opencv-$OPENCV_VERSION/build/install/* $CROSS_BUILT/local
		rsync -avz $WORKDIR/opencv-$OPENCV_VERSION/build/install/ $CROSS_BUILT/local
		sudo chown -R root:root $WORKDIR/opencv-$OPENCV_VERSION/build/install/*
#		sudo cp -r $WORKDIR/opencv-$OPENCV_VERSION/build/install/* $PIROOT/usr/local
		sudo rsync -avz $WORKDIR/opencv-$OPENCV_VERSION/build/install/ $PIROOT/usr/local
		sudo chown -R $USERNAME:$USERNAME $WORKDIR/opencv-$OPENCV_VERSION/build/install/*
		# Fix prefixex in pkgcongig files on PC and Pi
		sed -i 's|prefix='$WORKDIR'/opencv-'$OPENCV_VERSION'/build/install|prefix='$CROSS_BUILT'/local|' $CROSS_BUILT/local/lib/pkgconfig/opencv.pc
		sudo sed -i 's|prefix='$WORKDIR'/opencv-'$OPENCV_VERSION'/build/install|prefix=/usr/local|' $PIROOT/usr/local/lib/pkgconfig/opencv.pc
		echo "End deploy OpenCV."
	;;
	*)
		echo "buildopencv - invalid option! Valid options are: configure, build, deploy, clean"
	;;
	esac

}

buildgphoto2()
{
	if [ ! -z "$1" ]
	then
		FUNCPARAM=$1
	fi
 	case $FUNCPARAM in
 	configure)
		echo "Configuring gphoto2..."
		export PKG_CONFIG_PATH=/usr/share/arm-linux-gnueabihf/pkgconfig:$SYSROOT/usr/lib/pkgconfig
		export PKG_CONFIG_SYSROOT_DIR=$SYSROOT
		export PKG_CONFIG_EXECUTABLE="/usr/bin/arm-linux-gnueabihf-pkg-config"
		export LD_LIBRARY_PATH="$SYSROOT/usr/lib"
		export C_INCLUDE_PATH="$SYSROOT/usr/include"
		export CPLUS_INCLUDE_PATH="$SYSROOT/usr/include"
		#export PATH=$WORKDIR/libusb-$LIBUSB_VERSION:$PATH

		export CFLAGS="--sysroot $SYSROOT"
		export PATH="$PATH:/usr/bin/"
		cd $WORKDIR/libgphoto2-$LIBGPHOTO2_VERSION
		mkdir build
		autoreconf --install --symlink
		./configure \
		--host=arm-linux-gnueabihf \
		--prefix=$WORKDIR/libgphoto2-$LIBGPHOTO2_VERSION/build \
		--exec-prefix=$WORKDIR/libgphoto2-$LIBGPHOTO2_VERSION/build \
		-v |& tee $LOGDIR/configuregphoto2.log
		echo "End Configure gphoto2."
	;;
	build)
		echo "Building gphoto2..."
		cd $WORKDIR/libgphoto2-$LIBGPHOTO2_VERSION
		make -j$CPUCORES |& tee $LOGDIR/makegphoto2.log
		make install -j$CPUCORES |& tee $LOGDIR/makeinstallgphoto2.log
		echo "End build gphoto2."
	;;
	clean)
		echo "Cleaning gphoto2..."
#		rm -rf $WORKDIR/libgphoto2-$LIBGPHOTO2_VERSION/build
		rm -f $CROSS_BUILT/local/bin/gphoto2*
		rm -rf $CROSS_BUILT/local/include/gphoto2
		rm -rf $CROSS_BUILT/local/lib/libgphoto2
		rm -rf $CROSS_BUILT/local/lib/libgphoto2_port
		rm -f $CROSS_BUILT/local/lib/udev/*check-ptp-camera
		rm -f $CROSS_BUILT/local/lib/libgphoto2*
		rm -f $CROSS_BUILT/local/lib/pkgconfig/libgphoto2*
		rm -rf $CROSS_BUILT/local/share/doc/libgphoto2
		rm -rf $CROSS_BUILT/local/share/doc/libgphoto2_port
		rm -rf $CROSS_BUILT/local/share/libgphoto2
		rm -rf $CROSS_BUILT/local/share/libgphoto2_port
		rm -rf $CROSS_BUILT/local/share/locale
		rm -rf $CROSS_BUILT/local/share/man/man3/libgphoto2*
		echo "End clean gphoto2."
	;;
	deploy)
		echo "Deploying gphoto2..."
		cp -r $WORKDIR/libgphoto2-$LIBGPHOTO2_VERSION/build/* $CROSS_BUILT/local
		######### !!!!!!!! FIX pkgcongig files !!!!!!!! ##########################
		sed -i 's|prefix='$WORKDIR'/libgphoto2-'$LIBGPHOTO2_VERSION'/build|prefix='$CROSS_BUILT'/local|' $CROSS_BUILT/local/lib/pkgconfig/libgphoto2.pc
		sed -i 's|prefix='$WORKDIR'/libgphoto2-'$LIBGPHOTO2_VERSION'/build|prefix='$CROSS_BUILT'/local|' $CROSS_BUILT/local/lib/pkgconfig/libgphoto2_port.pc
		echo "Deploying on Pi not necessary as gphoto packages were installed from raspbian repo."
		echo "End deploy gphoto2."
	;;
	*)
		echo "buildgphoto2 - invalid option! Valid options are: configure, build, deploy, clean"
	;;
	esac
}

buildwiringpi()
{
	if [ ! -z "$1" ]
	then
		FUNCPARAM=$1
	fi
 	case $FUNCPARAM in
 	build)
		echo "Building wiringPi..."
#	   Make wiringPi library
		cd $WORKDIR/$WIRINGPI_VERSION/wiringPi
		make -j$CPUCORES DESTDIR=$CROSS_BUILT CC=/usr/bin/arm-linux-gnueabihf-gcc |& tee $LOGDIR/makewiringpilib.log
		make -j$CPUCORES install DESTDIR=$CROSS_BUILT LDCONFIG="" |& tee $LOGDIR/makeinstallwiringpilib.log
		mv $CROSS_BUILT/lib/libwiringPi.so $CROSS_BUILT/local/lib

#		Make wiringPiDev library
		cd $WORKDIR/$WIRINGPI_VERSION/devLib
		make -j$CPUCORES DESTDIR=$CROSS_BUILT INCLUDE=-I$CROSS_BUILT/local/include CC=/usr/bin/arm-linux-gnueabihf-gcc |& tee $LOGDIR/makewirilgpidevlib.log
		make -j$CPUCORES install DESTDIR=$CROSS_BUILT LDCONFIG="" |& tee $LOGDIR/makeinstallwiringpidevlib.log
		mv $CROSS_BUILT/lib/libwiringPiDev.so $CROSS_BUILT/local/lib

#		Make daemon
		cd $WORKDIR/$WIRINGPI_VERSION/wiringPiD
		make -j$CPUCORES DESTDIR=$CROSS_BUILT CC=/usr/bin/arm-linux-gnueabihf-gcc |& tee $LOGDIR/makewiringpidaemon.log
		sudo make -j$CPUCORES install DESTDIR=$CROSS_BUILT LDCONFIG="" |& tee $LOGDIR/makeinstallwiringpidaemon.log

#	   Make gpio
		cd $WORKDIR/$WIRINGPI_VERSION/gpio
		make -j$CPUCORES DESTDIR=$CROSS_BUILT CC=/usr/bin/arm-linux-gnueabihf-gcc |& tee $LOGDIR/makegpio.log
		mkdir $CROSS_BUILT/local/bin
		sudo make -j$CPUCORES install DESTDIR=$CROSS_BUILT |& tee $LOGDIR/makeinstallgpio.log
		echo "end build wiringPi."
	;;
	clean)
		echo "Cleaning wiringPi..."
		cd $WORKDIR/$WIRINGPI_VERSION/wiringPi
		make -j$CPUCORES clean
		cd $WORKDIR/$WIRINGPI_VERSION/devLib
		make -j$CPUCORES clean
		cd $WORKDIR/$WIRINGPI_VERSION/wiringPiD
		make -j$CPUCORES clean
		cd $WORKDIR/$WIRINGPI_VERSION/gpio
		make -j$CPUCORES clean
		sudo rm -f $CROSS_BUILT/local/bin/gpio
		sudo rm -f $CROSS_BUILT/local/include/*
		sudo rm -f $CROSS_BUILT/local/lib/libwiringPi*
		sudo rm -rf $CROSS_BUILT/local/man
		sudo rm -rf $CROSS_BUILT/local/sbin
		echo "End clean wiringPi."
	;;
	deploy)
		echo "wiringPi deploying is not necessary."
		echo "The wiringPi library is native installed in raspbian."
		echo "On PC, the wiringPi library files are built in $CROSS_BUILT/local"
	;;
	*)
		echo "buildwiringpi - invalid option! Valid options are: build, deploy, clean"
	;;
	esac
}

buildall()
{
	echo "Global build begin..."
	buildqt configure
	buildqt build
	buildopencv configure
	buildopencv build
	buildgphoto2 configure
	buildgphoto2 build
	buildwiringpi build
	echo
	echo "Global build end."
	echo
}

cleanall()
{
	echo "Global clean begin..."
	buildqt clean
	buildopencv clean
	buildgphoto2 clean
	buildwiringpi clean
	sudo rm -rf $CROSS_BUILT/local/*
	syncsystems pi
	echo
	echo "Global clean end."
	echo
}

deployall()
{
	echo "Global deploy begin..."
	buildqt deploy
	buildopencv deploy
	buildgphoto2 deploy
	buildwiringpi deploy
	sudo ssh root@$PI_IP 'ldconfig'
	syncsystems pi
	echo
	echo "Global deploy end."
	echo
}

deploytonewsys()
{
#	copyLocalRootPubkeyToPi
#	mountsystems
#	updatepi
#	sudo ssh root@$PI_IP 'apt-get install -y gphoto2'
	buildqt deploy
	buildopencv deploy
}



all()
{
	makefolders # OK
	installtrust # OK
	installpcprogs |& tee $LOGDIR/installpcporgs.log # OK
	mountsystems # OK
	installpiprogs |& tee $LOGDIR/installpiporgs.log # OK
	fetchdata # OK
	syncsystems pi # OK
	cd $WORKDIR # OK
	./sysroot-relativelinks.py $SYSROOT |& tee $LOGDIR/transformsymlinks-sysroot.log # OK
	./sysroot-relativelinks.py $PIROOT |& tee $LOGDIR/transformsymlinks-piroot.log # OK
	./sysroot-relativelinks.py $NFSROOT |& tee $LOGDIR/transformsymlinks-nfsroot.log # OK
	cleanall #OK
	buildall # OK
	deployall # OK
}

continue()
{
	echo
}

help()
{
	echo "Usage: `basename "$0"` < all | makefolders | installpcprogs | mountsystems | umountsystems | make_nfs_fstab | make_nfs_cmdlines |"
	echo "enablenfsonpi | setpinormal | setpinfs | syncsystems <local | nfs | pi> | copyLocalRootPubkeyToServer | copyLocalRootPubkeyToPi | "
	echo "installtrust | updatepi | installpiqtprogs | installpiopencvprogs | installpigphoto2progs | installpiprogs | exportpaths | "
	echo "makesymlinks | removesymlinks | fetchdata | makepkgconfigsymlinkstemplate |makepkgconfigsymlinks | removeredundantpkgconfig |"
	echo "buildqt | buildopencv | buildgphoto2 | buildwiringpi | buildall | deployall | cleanall | deplytonewsys()"
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
}

if [ -z $1 ]
then
	help
fi

$1
