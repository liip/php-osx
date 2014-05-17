#!/bin/sh
# creates a local.ch package for the packager

ORIPWD=$PWD
OS_VERSION=`sw_vers -productVersion | grep -o 10\..`
PHP_VERSION=`/usr/local/php5/bin/php -v | head -1`
PHP_VERSION_FULL=`echo $PHP_VERSION | egrep -o  '5\.[0-9]+\.[0-9][^ ]*' `
PHP_VERSION_MAJOR=`echo $PHP_VERSION_FULL | egrep -o  '5\.[0-9]+'`

# package type (subfolder in packager)

TYPE=$PHP_VERSION_MAJOR
echo "Detected PHP Version:" $TYPE;

if [ -z $1 ]; then
	echo ""
else
    if [[ $1 != $PHP_VERSION_MAJOR ]]; then
		echo "$1 and installed php version ($PHP_VERSION_MAJOR) mismatch. Aborting"
		exit 2;
	fi
fi

#if [[ $TYPE == "5.3" ]]; then
#        TYPE="tools"
#fi

if [[ $OS_VERSION == "10.8" ]]; then
	TYPE="$TYPE-10.8"
fi

echo "Creating package for TYPE: $TYPE";


# name of the package
NAME=frontenddev
# create a revision
REL=${PHP_VERSION_FULL}-$(date +%Y%m%d-%H%M%S)


# root folder for the package creation
root="/tmp/$NAME-package"

USER=chregu

# check if php was build localy
if  [ ! -d "/usr/local/php5" ]; then
	echo "you need to build php first!"
	exit 1
fi
if [ -h "/usr/local/php5" ]; then
	echo "Target is a symbolic link! Looks like you have a php5 package installed! Done..."
	exit 1
fi

echo "packaging ..."

# remove root if it exists
[ -d "$root" ] && rm -rf $root

#create the package root folder
mkdir $root
mkdir -p $root/usr/local/

# copy the php5 package contents
cp -R /usr/local/php5 $root/usr/local/php5-$REL

# create metadata
mkdir $root/pkg
echo "name: $TYPE-$NAME
version: $REL
#depends: tools-memcached
" >$root/pkg/info


echo "downloading latest php.ini-liip"
curl -k https://svn.liip.ch/repos/public/misc/php-ini/php.ini-development >> $root/usr/local/php5-$REL/php.d/99-liip-developer.ini

# generate post-initial (executed only on the inital, first installation)
cp deploy/post-initial $root/pkg/post-initial

# generate post-install
echo "# post-install" >$root/pkg/post-install
echo "# symlink" >>$root/pkg/post-install
echo "rm -f '/usr/local/php5' && ln -s '/usr/local/php5-$REL' '/usr/local/php5'" >>$root/pkg/post-install
echo "# create php.ini based on php.ini-development" >>$root/pkg/post-install
echo "cp /usr/local/php5/lib/php.ini-development /usr/local/php5/lib/php.ini" >>$root/pkg/post-install
cat  update_httpd_conf.sh >> $root/pkg/post-install
echo "# restart apache" >>$root/pkg/post-install
echo "echo 'Restarting Apache'" >>$root/pkg/post-install
echo "/usr/sbin/apachectl configtest && /usr/sbin/apachectl restart" >>$root/pkg/post-install

echo "Tag the release"
ODIR=$PWD
cd ../build-entropy-php/
git tag $REL-$TYPE
cd $ODIR


# tar the package
cd $root

echo "Tar the package $TYPE-$NAME-$REL.tar.bz2"
tar  -cjf ../$TYPE-$NAME-$REL.tar.bz2 --exclude 'share/doc/' --exclude 'man/' . || exit 1

# upload to liip
UPLOADDIR=/Volumes/s3-liip/php-osx.liip.ch/
UPLOADDIR=/tmp/
mkdir -p $UPLOADDIR/install/$TYPE/$NAME/

cd $ORIPWD

php uploadFile.php $root/../$TYPE-$NAME-$REL.tar.bz2 install/$TYPE/$NAME/$TYPE-$NAME-$REL.tar.bz2 "application/x-gzip"

echo "install/$TYPE/$NAME/$TYPE-$NAME-$REL.tar.bz2" > $UPLOADDIR/install/$TYPE-$NAME-latest.dat

php uploadFile.php $root/../install/$TYPE-$NAME-latest.dat install/$TYPE-$NAME-latest.dat "text/plain"

tar -czf /tmp/packager.tgz packager && php uploadFile.php /tmp/packager.tgz packager/packager.tgz "application/x-gzip"

echo "Get latest uploaded versions on S3\n";
php getLatestVersions.php > index.html.bottom
echo "</pre></body></html>" >> index.html.bottom
cat index.html.tmpl index.html.bottom > index.html


php uploadFile.php index.html index.html "text/html"
php uploadFile.php install.sh install.sh "text/plain"

#scp ../$TYPE-$NAME-$REL.tar.gz $USER@dev2.liip.ch:/home/liip/dev2/install/$TYPE/$NAME/
#ssh -l $USER dev2.liip.ch "ln -sf ../${TYPE}/${NAME}/${TYPE}-${NAME}-${REL}.tar.gz /home/liip/dev2/install/www/${TYPE}-${NAME}.tar.gz"

echo "done ..."


