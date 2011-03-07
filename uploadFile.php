<?php

$src = $argv[1];
$dst = $argv[2];
$type = $argv[3];

if(!$type) {
    $type = "text/html";
}
if(!$dst) {
    $dst = $src;
}

require_once 'AWSSDKforPHP/sdk.class.php';
include("config.inc.php");

upload($src,$dst,$type);


function upload($src,$dst,$type = 'text/plain') {
// Instantiate the class

echo "Upload $src to $dst as $type\n";
$s3 = new AmazonS3();
 
$response = $s3->create_object('php-osx.liip.ch', $dst, array(
    'fileUpload' => $src,
    'acl' => AmazonS3::ACL_PUBLIC,
    'contentType' => $type,
    'storage' => AmazonS3::STORAGE_REDUCED,
    
));
 
// Success?

if ($response->isOK()) {
    print "done\n";
} else {
    print "failed \n";
}

}
