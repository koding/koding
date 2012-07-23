<?php
die('ping and die');
$path = $_GET['path'];
echo "<pre>";
print_r(getDirectoryList($path));

function getDirectoryList ($directory) 
{

  // create an array to hold directory list
  $results = array();

  // create a handler for the directory
  $handler = opendir($directory);

  // open directory and walk through the filenames
  while ($file = readdir($handler)) {

    // if file isn't this directory or its parent, add it to the results
    if ($file != "." && $file != "..") {
      $results[] = $file;
    }

  }

  // tidy up: close the handler
  closedir($handler);

  // done!
  return $results;

}

function getFileList($dir)
{
  // array to hold return value
  $retval = array();

  // add trailing slash if missing
  if(substr($dir, -1) != "/") $dir .= "/";

  // open pointer to directory and read list of files
  $d = @dir($dir) or die("getFileList: Failed opening directory $dir for reading");
  while(false !== ($entry = $d->read())) {
    // skip hidden files
    if($entry[0] == ".") continue;
    if(is_dir("$dir$entry")) {
      $retval[] = array(
        "name" => "$dir$entry/",
        "type" => filetype("$dir$entry"),
        "size" => 0,
        "lastmod" => filemtime("$dir$entry")
      );
    } elseif(is_readable("$dir$entry")) {
      $retval[] = array(
        "name" => "$dir$entry",
        "type" => mime_content_type("$dir$entry"),
        "size" => filesize("$dir$entry"),
        "lastmod" => filemtime("$dir$entry")
      );
    }
  }
  $d->close();

  return $retval;
}
  