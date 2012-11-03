<?php

$headers = getallheaders();
$file = readfile(urldecode($_GET['url']));
$finfo = finfo_buffer($file);

//if (in_array($origin, array('https://koding.com'))) {
  header('Content-type: '.$finfo);
  echo $file;
//}
