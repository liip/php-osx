# try to update http.conf if there's the standard config
SEARCH=`grep    "LoadModule.*php5_module.*/usr/local/php5/libphp5.so" httpd.conf`
if [[ -z $SEARCH ]]
then
cp httpd.conf httpd.conf.before-phposx
sed 's/\(#LoadModule.*php5_module.*libexec\/apache2\/libphp5.so.*\)/\1\
LoadModule php5_module \/usr\/local\/php5\/libphp5.so/g' < httpd.conf > httpd.conf.phposx
	if [[ -s httpd.conf.phposx ]]
	then
		cp httpd.conf.phposx httpd.conf
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
