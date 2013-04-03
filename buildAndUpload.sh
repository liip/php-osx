#!/bin/sh

run() {
  "$@"
  if [ $? -ne 0 ]
  then
    echo "$* failed with exit code $?"
    exit 1
  else
    return 0
  fi
}

OS_VERSION=`sw_vers -productVersion | grep -o 10\..`

if [[ $OS_VERSION == "10.8" ]]; then
	OSNAME="mountainlion"
else
	OSNAME="snowleopard"
fi

if [ -z $1 ]; then
	echo "Please state the PHP version to be compiled as 5.3, 5.4 or 5.5"
	exit 1;
fi

PHP_VERSION=$1
PHP_VERSION_UNDERSCORE=$(echo $PHP_VERSION | sed -e 's/\./_/g')


cd ../build-entropy-php

#git remote update

run git co ${PHP_VERSION_UNDERSCORE}_$OSNAME
run git rebase
run sudo bash ./deletePeclSources.sh

run sudo bash ./build-php.sh

cd ../php-osx

run bash create_package.sh $PHP_VERSION
