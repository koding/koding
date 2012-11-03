<?php

//$headers = getallheaders();
$buffer = file_get_contents(urldecode($_GET['url']));

$finfo = new finfo(FILEINFO_MIME_TYPE);
header('Content-type: '.$finfo->buffer($buffer));
print $buffer;

//if (in_array($origin, array('https://koding.com'))) {
//  header('Content-type: '.$finfo);
//  echo $file;
//}
