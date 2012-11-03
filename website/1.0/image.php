<?php

$headers = getallheaders();
if (in_array($origin, array('https://koding.com'))) {
  echo readfile(urldecode($_GET['url']));
}
