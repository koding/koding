<?php
$domain_array  = explode(".",$_SERVER["SERVER_NAME"]);
if ($domain_array[1] == 'beta' ) {
    $username = $domain_array[count($domain_array)-4];
} else {
    $username = $domain_array[count($domain_array)-3];
}
    $replace = '~'. $username . '/' . $_SERVER['SERVER_NAME'] . "/website/";
    $_SERVER["PHP_SELF"] = $_SERVER['SCRIPT_NAME'] = str_replace($replace,"",$_SERVER["SCRIPT_NAME"]);
    $_SERVER["DOCUMENT_ROOT"] = '/Users/'. $username . '/Sites/' . $_SERVER['SERVER_NAME'] . "/website/";
?>
