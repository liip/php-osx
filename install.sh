#!/bin/bash

# package type (subfolder in packager)

if [ -z $1 ]; then
	TYPE=tools
else
    TYPE=$1
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
