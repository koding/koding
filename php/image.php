<?php

$url = $_GET['url'];

$ch = curl_init ($url);
curl_setopt($ch, CURLOPT_HEADER, 1);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_BINARYTRANSFER, 1);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, 10);

$output = curl_exec($ch);
curl_close ($ch);

$output = explode("\r\n\r\n", $output, 2);
$header = explode("\r\n", $output[0]);

foreach ($header as $key => $val) {
    if ($key > 0 && stripos($val, "Transfer-Encoding:") !== 0) {
        header($val);
    }
}

echo $output[1];
