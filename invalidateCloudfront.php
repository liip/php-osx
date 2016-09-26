<?php
require_once 'AWSSDKforPHP/sdk.class.php';
include("config.inc.php");

$cf = new AmazonCloudFront();
$cf->create_invalidation("E3GN2MEVU47B0I", uniqid("uploadScript"), '*');




