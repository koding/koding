<?php

$a = file_put_contents('/opt/kfmjs/website/1.0/tmp/test.out', var_export(
  file_get_contents('php://input'), true
).PHP_EOL, FILE_APPEND);