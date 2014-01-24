#!/bin/bash

# package type (subfolder in packager)

if [ -z $1 ]; then
	TYPE=5.3
else
    TYPE=$1
fi

if [[ $TYPE != "force" ]]; then
	OS_VERSION=`sw_vers -productVersion | grep -o 10\..`
	if [[ $OS_VERSION == "10.9" ]]; then
		echo "Detected OS X Mavericks 10.9. All ok."
	elif [[ $OS_VERSION == "10.8" ]]; then
		echo "Detected OS X Mountain Lion 10.8. All ok."
	elif [[ $OS_VERSION == "10.7" ]]; then
		echo "Detected OS X Lion 10.7. All ok."
	elif [[ $OS_VERSION == "10.6" ]]; then
		echo "Detected OS X Snow Leopard 10.6. All ok."
	else
		echo "****"
		echo "Your version of OS X ($OS_VERSION) is not supported, you need at least 10.6"
		echo "Stopping installation..."
		echo "If you think that's wrong, try"
		echo "****"
		echo "curl -o install.sh -s http://php-osx.liip.ch/install.sh | bash install.sh force"
		echo "****"
		exit 2
	fi
	HAS64BIT=`sysctl -n hw.cpu64bit_capable 2> /dev/null`
	if [[ $HAS64BIT != 1 ]]; then
		echo "****"
		echo "ERROR! 32 BIT NOT SUPPORTED!"
		echo "****"
		echo "No 64bit capable system found. Your hardware is too old."
		echo "We don't support that (yet). Patches are welcome ;)"
		echo "If you think that's wrong, try"
		echo "****"
		echo "curl -o install.sh -s http://php-osx.liip.ch/install.sh | bash install.sh force"
		echo "****"
		exit 1
	fi
fi

if [[ $TYPE = "force" ]]; then
	if [ -z $2 ]; then
		TYPE=5.3
	else
		TYPE=$2
	fi
fi

if [[ $OS_VERSION = "10.8" ]] || [[ $OS_VERSION = "10.9" ]]; then
	if [[ $TYPE = "5.4" ]]; then
	    TYPE=5.4-10.8
	elif [[ $TYPE = "5.5" ]]; then
	    TYPE=5.5-10.8
	elif [[ $TYPE = "5.6" ]]; then
	    TYPE=5.6-10.8
	elif [[ $TYPE = "5.3" ]]; then
	   TYPE=5.3-10.8
	fi
fi
if [[ $TYPE = "5.6" ]]; then
	echo "PHP 5.6 is nota available yet for OS X < 10.8"
	exit 1
fi



echo "Get packager.tgz";
curl -s -o /tmp/packager.tgz http://php-osx.liip.ch/packager/packager.tgz
echo "Unpack packager.tgz";
echo "Please type in your password, as we want to install this into /usr/local"
if [ !  -d /usr/local ] ; then sudo mkdir /usr/local; fi
sudo  tar -C /usr/local -xzf /tmp/packager.tgz
echo "Start packager (may take some time)";
sudo /usr/local/packager/packager.py install $TYPE-frontenddev
cd $ORIPWD
