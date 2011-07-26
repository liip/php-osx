#!/bin/bash

# package type (subfolder in packager)

if [ -z $1 ]; then
	TYPE=tools
else
    TYPE=$1
fi

if [[ $TYPE != "force" ]]; then
	OS_VERSION=`sw_vers -productVersion | grep -o 10\..`
	if [[ $OS_VERSION == "10.7" ]]; then
#		echo "****"
#		echo "Mac OS X 10.7 Lion is not officially supported yet,"
#		echo " but it works on our test system."
#		echo "Nothing guaranteed, installing nevertheless"
#		echo "****"
#		sleep 2
	elif [[ $OS_VERSION != "10.6" ]]; then
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
		TYPE=tools
	else
		TYPE=$2
	fi
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
