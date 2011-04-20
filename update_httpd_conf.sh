# try to update http.conf if there's the standard config
SEARCH=`grep    "LoadModule.*php5_module.*/usr/local/php5/libphp5.so" httpd.conf`
if [[ -z $SEARCH ]]
then
cp /etc/apache2/httpd.conf /etc/apache2/httpd.conf.before-phposx
sed 's/\(#LoadModule.*php5_module.*libexec\/apache2\/libphp5.so.*\)/\1\
LoadModule php5_module \/usr\/local\/php5\/libphp5.so/g' < /etc/apache2/httpd.conf > /etc/apache2/httpd.conf.phposx
	if [[ -s /etc/apache2/httpd.conf.phposx ]]
	then
		cp /etc/apache2/httpd.conf.phposx /etc/apache2/httpd.conf
		echo "LoadModule php5_module /usr/local/php5/libphp5.so"
		echo "added to your httpd.conf"
	else 
    		echo "WARNING: For some reason, we couldn't adjust your httpd.conf"
		echo "Make sure the line "
		echo "LoadModule php5_module /usr/local/php5/libphp5.so"
		echo "is in it";
	fi
else 
	echo "LoadModule php5_module /usr/local/php5/libphp5.so"
	echo "is already in your httpd.conf. All looks good."
fi

# try adjusting /usr/sbin/envvars
DYLD_PATH=`. /usr/sbin/envvars && echo $DYLD_FALLBACK_LIBRARY_PATH | grep /usr/local/php5/lib`
if [[ -z $DYLD_PATH ]]
then
echo 'DYLD_FALLBACK_LIBRARY_PATH="/usr/local/php5/lib:$DYLD_FALLBACK_LIBRARY_PATH"' >> /usr/sbin/envvars
echo 'export DYLD_FALLBACK_LIBRARY_PATH' >> /usr/sbin/envvars
echo "Added /usr/local/php5/lib to DYLD_FALLBACK_LIBRARY_PATH in /usr/sbin/envvars"
fi
