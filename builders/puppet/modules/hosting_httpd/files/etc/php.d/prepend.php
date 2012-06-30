<?php
$domain_array   = explode(".",$_SERVER["SERVER_NAME"]);
$username = $domain_array[count($domain_array)-4];
$replace = '~'. $username . '/' . $_SERVER['SERVER_NAME'] . "/website/";
$_SERVER["PHP_SELF"] = $_SERVER['SCRIPT_NAME'] = str_replace($replace,"",$_SERVER["SCRIPT_NAME"]);
?>
