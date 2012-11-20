<?php

$mime_map = array(
  'css' => 'text/css',
  'js'  => 'text/javascript',
);

$url = $_GET['url'];

if (!preg_match('/^(http|https)/', $url)) {
  header('HTTP/1.0 400 Bad Request');
  die();
}

$extension = array_pop(explode('.', $url));

//$headers = getallheaders();

$buffer = file_get_contents(urldecode($_GET['url']));

if (array_key_exists($extension, $mime_map)) {
  header('Content-type: '.$mime_map[$extension]);
} else {
  $finfo = new finfo(FILEINFO_MIME_TYPE);
  header('Content-type: '.$finfo->buffer($buffer));
}
print $buffer;

//if (in_array($origin, array('https://koding.com'))) {
//  header('Content-type: '.$finfo);
//  echo $file;
//}
