# try to update http.conf if there's the standard config
SEARCH=`httpd -MT 2> /dev/null| grep php5`
if [[ -n $SEARCH ]]
then
#deactivate php5_module in httpd.conf
apxs -e -A -n php5 libphp5.so 2> /dev/null
#search of there's an old entry to /usr/local/php5/libphp5.so in httpd.conf
SEARCH2=`grep /usr/local/php5/libphp5.so /etc/apache2/httpd.conf `
if [[ -n $SEARCH2 ]]
then
cp /etc/apache2/httpd.conf /etc/apache2/httpd.conf.before-phposx
# remove the old line from httpd.conf
sed 's/LoadModule php5_module \/usr\/local\/php5\/libphp5.so//' < /etc/apache2/httpd.conf.before-phposx > /etc/apache2/httpd.conf
fi
fi

# OS X 10.6 doesn't have an other directoty
if [[ -d /etc/apache2/other ]]
then
    if [[ ! -h /etc/apache2/other/+php-osx.conf ]]
    then
      echo "Create symlink /usr/local/php5/entropy-php.conf /etc/apache2/other/+php-osx.conf"
      ln -s /usr/local/php5/entropy-php.conf /etc/apache2/other/+php-osx.conf
    fi
else
    if [[ ! -h /etc/apache2/sites/+php-osx.conf ]]
    then
      echo "Create symlink /usr/local/php5/entropy-php.conf /etc/apache2/sites/+php-osx.conf"
      ln -s /usr/local/php5/entropy-php.conf /etc/apache2/sites/+php-osx.conf
    fi
fi

# try adjusting /usr/sbin/envvars
DYLD_PATH=`. /usr/sbin/envvars && echo $DYLD_LIBRARY_PATH | grep /usr/lib:`
if [[ -n $DYLD_PATH ]]
then
echo "#added by php-osx" >> /usr/sbin/envvars
echo 'DYLD_LIBRARY_PATH="'` echo -n $DYLD_LIBRARY_PATH | sed 's/\/usr\/lib://' `'"' >> /usr/sbin/envvars
echo 'export DYLD_LIBRARY_PATH' >> /usr/sbin/envvars
echo "Removed /usr/lib from DYLD_LIBRARY_PATH in /usr/sbin/envvars"
fi
