<?php


require_once 'AWSSDKforPHP/sdk.class.php';
include("config.inc.php");

print getObject('5.6-10.8');
print "\n";
print getObject('5.5-10.10');
print getObject('5.5-10.8');
print getObject('5.5');
print "\n";
print getObject('5.4-10.8');
print getObject('5.4');
print "\n";
print getObject('5.3-10.8');
print getObject('5.3');

function getObject($src) {
    // Instantiate the class

    $s3 = new AmazonS3();


    $response = $s3->get_object(
        'php-osx.liip.ch',
        'install/'.$src.'-frontenddev-latest.dat'
    );


    if ($response->isOK()) {
        preg_match("/([5-9]\.[0-9]+)-(10\.[0-9]+){0,1}-*frontenddev-([0-9\.(alphabeta)]+)-([0-9]+)/",$response->body,$matches);
        if ($matches[2] == "") {
            $matches[2] = "10.6/10.7";
        }
        if ($matches[2] == "10.8") {
            $matches[2] = "10.8/10.9";
        }
        preg_match("/([0-9]{4})([0-9]{2})([0-9]{2})/",$matches[4],$date);
        $text = "PHP " . $matches[3] . " for OS X " . $matches[2] . " uploaded at " . $date[1] ."-" . $date[2] . "-" . $date[3]  ."\n";


    } else {
        print "failed \n";
    }
    return $text;

}
