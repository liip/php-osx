#!/bin/bash

# package type (subfolder in packager)

# default version to install
DEFAULT=5.6

if [ -z $1 ]; then
	TYPE=$DEFAULT
else
	TYPE=$1
fi

if [[ $TYPE = "force" ]]; then
	if [ -z $2 ]; then
		TYPE=$DEFAULT
	else
		TYPE=$2
	fi
fi

if [[ $TYPE != "force" ]]; then
    OS_VERSION_PATCH=`sw_vers -productVersion | egrep --color=never -o '10\.[0-9]+\.[0-9]+'`
    OS_VERSION=`echo $OS_VERSION_PATCH | cut -f 1,2 -d "."`
    OS_SUB=`echo $OS_VERSION_PATCH | cut -f 2 -d "."`
    OS_SUB=`expr $OS_SUB`
    OS_PATCH=`echo $OS_VERSION_PATCH | cut -f 3 -d "."`
    OS_PATCH=`expr $OS_PATCH`
    if [[ $OS_VERSION == "10.15" ]]; then
            echo "Detected macOS Catalina 10.15. All ok."
    elif [[ $OS_VERSION == "10.14" ]]; then
        if [[ $OS_PATCH < 4 ]]; then
            echo "****"
            echo "[WARNING]"
            echo "Detected macOS Mojave <= 10.14.3. There are serious issues with it, due to the original apache not loading"
            echo "foreign libraries anymore. PHP within apache will most certainly not work anymore if you proceed!"
            echo "The cli version still will."
            echo "See this issue at https://github.com/liip/php-osx/issues/249 for details and discussion"
            echo "****"
            if [[ $1 = "force" ]]; then
              echo "Proceeding"
            else
                echo "Restart this script with"
                echo " curl -s https://php-osx.liip.ch/install.sh | bash -s force $1"
                echo "to really install it"
                echo "****"
                exit 1
            fi
        else
            echo "Detected macOS Mojave >= 10.14.4. All ok."
        fi
	elif [[ $OS_VERSION == "10.13" ]]; then
                echo "Detected macOS High Sierra 10.13. All ok."
	elif [[ $OS_VERSION == "10.12" ]]; then
		echo "Detected macOS Sierra 10.12. All ok."
	elif [[ $OS_VERSION == "10.11" ]]; then
		echo "Detected OS X El Capitan 10.11. All ok."
	elif [[ $OS_VERSION == "10.10" ]]; then
		echo "Detected OS X Yosemite 10.10. All ok."
	elif [[ $OS_VERSION == "10.9" ]]; then
		echo "Detected OS X Mavericks 10.9 All ok."
	elif [[ $OS_VERSION == "10.8" ]]; then
		echo "Detected OS X Mountain Lion 10.8 All ok."
	elif [[ $OS_VERSION == "10.7" ]]; then
		echo "Detected OS X Lion 10.7. All ok."
	elif [[ $OS_VERSION == "10.6" ]]; then
		echo "Detected OS X Snow Leopard 10.6 All ok."
	else
		echo "****"
		echo "Your version of OS X ($OS_VERSION) is not supported, you need at least 10.6"
		echo "Stopping installation..."
		echo "If you think that's wrong, try"
		echo "****"
		echo "curl -o install.sh -s https://php-osx.liip.ch/install.sh | bash install.sh force"
		echo "****"
		exit 2
	fi
	if [[ -f /usr/sbin/sysctl ]]; then
	    SYSCTL="/usr/sbin/sysctl"
	elif [[ -f /sbin/sysctl ]]; then
	    SYSCTL="/sbin/sysctl"
	else
	    SYSCTL="sysctl"
	fi

	HAS64BIT=`$SYSCTL -n hw.cpu64bit_capable 2> /dev/null`
	if [[ $HAS64BIT != 1 ]]; then
		echo "****"
		echo "ERROR! 32 BIT NOT SUPPORTED!"
		echo "****"
		echo "No 64bit capable system found. Your hardware is too old."
		echo "We don't support that (yet). Patches are welcome ;)"
		echo "If you think that's wrong, try"
		echo "****"
		echo "curl -o install.sh -s https://php-osx.liip.ch/install.sh | bash install.sh force"
		echo "****"
		exit 1
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

# 10.11 and later should be compatible with 10.10 versions for now.
# See https://github.com/liip/build-entropy-php/issues/16 for more
if [[ $OS_SUB -gt 9 ]]; then
	if [[ $TYPE = "5.4" ]]; then
		TYPE=5.4-10.10
	elif [[ $TYPE = "5.5" ]]; then
		TYPE=5.5-10.10
	elif [[ $TYPE = "5.6" ]]; then
		TYPE=5.6-10.10
	elif [[ $TYPE = "7.0" ]]; then
		TYPE=7.0-10.10
	elif [[ $TYPE = "7.1" ]]; then
		TYPE=7.1-10.10
	elif [[ $TYPE = "7.2" ]]; then
		TYPE=7.2-10.10
	elif [[ $TYPE = "7.3" ]]; then
		TYPE=7.3-10.10
	elif [[ $TYPE = "5.3" ]]; then
		TYPE=5.3-10.10
	fi
fi

if [[ $TYPE = "5.6" ]]; then
	echo "PHP 5.6 is not available for OS X < 10.8"
	exit 1
elif [[ $TYPE = "7.3" ]]; then
	echo "PHP 7.3 is not available for OS X < 10.10"
	exit 1
elif [[ $TYPE = "7.2" ]]; then
	echo "PHP 7.2 is not available for OS X < 10.10"
	exit 1
elif [[ $TYPE = "7.1" ]]; then
	echo "PHP 7.1 is not available for OS X < 10.10"
	exit 1
elif [[ $TYPE = "7.0" ]]; then
	echo "PHP 7.0 is not available for OS X < 10.10"
	exit 1
fi



echo "Get packager.tgz";
curl -s -o /tmp/packager.tgz https://s3-eu-west-1.amazonaws.com/php-osx.liip.ch/packager/packager.tgz

echo "Unpack packager.tgz";
echo "Please type in your password, as we want to install this into /usr/local"
if [ !  -d /usr/local ] ; then sudo mkdir /usr/local; fi
sudo  tar -C /usr/local -xzf /tmp/packager.tgz

if [[ -f /usr/bin/python2.7 ]]; then
   PYTHONPATH=/usr/bin/python2.7
elif [[ -f /usr/bin/python2.6 ]]; then
   PYTHONPATH=/usr/bin/python2.6
elif [[ -f /usr/bin/python ]]; then
   PYTHONPATH=/usr/bin/python
else
   PYTHONPATH=$(which python)
fi

echo "Start packager (may take some time) using $PYTHONPATH";

sudo $PYTHONPATH /usr/local/packager/packager.py install $TYPE-frontenddev
cd $ORIPWD
echo "Finished."
