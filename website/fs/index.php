<?php
ini_set('display_errors','on');
require_once('Executor.php');
require_once('systemProcessNew/trunk/src/classes/systemProcess.php');

$e = new Executor();
$e->run($_GET);