Install cross-compile environment for Qt, OpenCV, gphoto2, WiringPi on Ubuntu

https://it-dir.felnet.ro/index.php/uncategorised/252-setting-up-cross-compiling-environment-on-ubuntu-for-raspberry-pi-qt-opencv-gphoto2-wiringpi

Cross-compiling machine: PC - running Ubuntu 17.10
Target machine: Raspberry Pi 3 Model B - running Raspbian Stretch
NFS server: Debian Stretch.

Introduction, blablabla...


The present setup allows the Pi to boot from its own SD or from the local network, using NFS.

Prerequisites - on Raspberry Pi:

Update Raspbian Stretch and upgrade its firmware drivers and enable SSH

Prepare a SD with Raspbian Stretch, boot the Pi, connect it to the network  and update it:
$ sudo apt update
$ sudo apt upgrade

Upgrade the Pi firmware:
$ sudo apt install rpi-update
$ sudo rpi-update

Enable SSH service:
$ sudo systemctl enable ssh.service
$ sudo systemctl start ssh.service

The rest of the setup will be done remotely from the PC.


Prerequisites on PC (Ubuntu 17.10):

Install Qt: - go to https://www.qt.io/download , chose a platform (commercial or free) and dowload the installer. You will have to login in order to be able to download, you will have to register, if you haven't done it before, to get the login data.

Once the installer is downloaded, make it executable and run it:

$ chmod 764 ~/Downloads/qt-unified-linux-x64-3.0.2-online.run

$ ~/Downloads/qt-unified-linux-x64-3.0.2-online.run

The installer will ask you for your login data, then chose the installation folder and components to install (chose the latest Qt and Qt creator) before starting installation.

Enable sources repos: Run "Software Updater", click "Settings" button, select "Ubuntu Software" tab and check "Source code" checkbox.

Install net-tools:

$ apt install net-tools

Boot the Raspberry Pi, connect it to the local network and run the setup script.

script, blablabla

 

Configure Qt Creator

Go to Tools/Options -> Devices
  Add
    Generic Linux Device
    Give it a name (Raspberry Pi), enter IP address, user & password
    Finish

Go to Tools/Options/Build & Run -> Compilers

   As gcc-arm-linux-gnueabihf and g++-arm-linux-gnueabihf packages were installed by the script,
the corresponding compilers should be in the compilers list.
   
    Check C compiler, you will use the GCC arm C 7 (/usr/bin/arm-linux-gnueabihf-gcc-7) compiler.
    If it is not in the list, add a new compiler:
    Compiler path: /usr/bin/arm-linux-gnueabihf-g++
    ABI: arm-linux-generic-elf-32bit

  Check C++ compiler, you will use the GCC arm C++ 7 (/usr/bin/arm-linux-gnueabihf-g++-7) compiler.
    If it is not in the list, add a new compiler:
    Compiler path: /usr/bin/arm-linux-gnueabihf-g++
    ABI: arm-linux-generic-elf-32bit

Go to Tools/Options -> Debuggers
  Add
    Give it a name and select the arm debugger in tools folder.
    ~/raspi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-gdb

Go to Tools/Options -> Build & Run -> Qt Versions
  Check if an entry with ~/raspi/qt5pc/bin/qmake shows up. If not, select it to be added.

  
Go to Tools/Options -> Build & Run
  Kits
    Add
      Give it a name (Raspberry Pi)
      Filesystem Name: Raspbian (optional)
      Device Type: Generic Linux Device
      Device: the one we just created (Raspberry Pi)
      Sysroot: ~/raspi/sysroot
      Compiler: GCC arm C 7 or the one that was just added
      Debugger: GCC arm C++ 7 or the one that was just added
      Qt version: Qt <version> (qt5pc) - the one we added under Qt Versions
      Qt mkspec: leave empty

 

Open a Qt project, click on the "Projects" icon in the left pane (wrench key), under "Build & Run" click the inactive Raspberry Pi kit to activate it.

 

To cross-compile the project for Raspberry Pi, in the profile selector (in the left pane) select the Raspberry Pi kit.

 

To use the compiled libraries in the project, edit the project file (*.pro) and add:
INCLUDEPATH += /home/<username>/raspi/cross_built/local/include
LIBS += `pkg-config /home/<username>/raspi/cross_built/local/lib/pkgconfig/opencv.pc --libs`
LIBS += -L/home/<username>/raspi/cross_built/local/lib -ltbb -lgphoto2 -lgphoto2_port -lwiringPi

 

 Compile the project and deploy it on the running Raspberry Pi.



 

