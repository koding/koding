<?php
ini_set('display_errors','on');
require_once('Executor.php');
require_once('systemProcess/trunk/src/classes/systemProcess.php');

$e = new Executor();
$e->nginx_run($_GET);