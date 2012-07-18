<?php

 
openlog("[PHP Vhost]",LOG_NDELAY, LOG_LOCAL4);

$alert_mail = "aleksey@koding.com";
$vhost_base_dir  = "public_html";

$default_vhost_files = array("/opt/kfmjs/kites/sharedHosting/defaultVhostFiles/httpdocs/index.html" => 0644,
                             "/opt/kfmjs/kites/sharedHosting/defaultVhostFiles/httpdocs/perl.pl"    => 0755,
                             "/opt/kfmjs/kites/sharedHosting/defaultVhostFiles/httpdocs/php.php"    => 0644,
                             "/opt/kfmjs/kites/sharedHosting/defaultVhostFiles/httpdocs/python.py"  => 0755,
                             "/opt/kfmjs/kites/sharedHosting/defaultVhostFiles/httpdocs/ruby.rb"    => 0755,
                            );

// parse command line params
$command_name = $argv[0];
$options = getopt("i::d::u:v:");
if (empty($options) or empty($options['u']) or empty($options['v'])) {
    echo "
Usage : $command_name [ -i ] [ -d ] -u <username> -v <virtual host name>
where
   -i = make home dir and vhost . omit this option if you want to make just new vhost for existent user 
   -d = remove vhost for username
   -u = Koding username 
   -v = virtual hostname (fqnd) for username
\n";      
exit;
}

$username = $options['u'];
$vhostname = $options['v'];


 
function logger ($message, $priority) {
    global $alert_mail;

    if ( $priority == LOG_ERR ) { 
        mail($alert_mail,"vhost error!",$message);
    }
    echo "$message\n";
    syslog($priority, $message);
}

function check_user($username) {
    $user = posix_getpwnam($username);
    if (!$user) {
        logger("[ERROR] Could not find user $username", LOG_ERR);
        return false;
    } else {
        return $user['dir'];
    }
}


function make_home_dir ($username) {
     /*
        This method will create home directory for username

        Parameters:
            $username  # string: username should be lowercase

        Return Values:
            Returns TRUE on success or FALSE on failure.
    */   

    global $vhost_base_dir;
    
    $home = check_user($username);
    if (!$home) {
        return false;
    } else {
        $vhostdir = "$home/$vhost_base_dir";
    }

    if ( ! mkdir($vhostdir, 0755, 1) ) {
        logger("[ERROR] Could not create home dir and vhost dir $home/$vhost_base_dir", LOG_ERR);
        return false;
    } else {
        if ( ! chown($home, $username) or ! chgrp($home, $username) ) {
            logger("[ERROR] Could not change owner or group on home directory $home to user $username", LOG_ERR);
            return false;
        } else {
            logger("[OK] home dir $home and folder for vhosts $home/$vhost_base_dir created",LOG_INFO);
            return true;
        }

    }
}

function copy_vhost_files ($vhost_path, $username) {

      global $default_vhost_files;

      foreach ($default_vhost_files as $file => $permissions) {
            $dest = "$vhost_path/" . basename($file);
            if ( ! copy($file, $dest) ) {
                logger("[ERROR] Could not copy $file to $dest", LOG_ERR);
                return false;
            } else {
                if ( ! chown($dest, $username) or ! chgrp($dest, $username) ) {
                    logger("[ERROR] Could not change owner or group on $dest to user $username", LOG_ERR);
                    return false;
                } else {
                    if ( ! chmod($dest,$permissions) ) {
                        logger("[ERROR] Could not change permissions on file $dest to $permissions", LOG_ERR);
                        return false;
                    }
               }
           }
       } // end of foreach
       return true;
}

function vhost_add ($username, $vhostname) {

      /*
        This method will create virtual host for username

        Parameters:
            $username  # string: username should be lowercase
            $vhostname # string: virtual host name (FQDN)

        Return Values:
            Returns TRUE on success or FALSE on failure.
    */   

    global $vhost_base_dir;

    $home = check_user($username);
    if (!$home) {
        return false;
    } else {
        $vhost_path = "$home/$vhost_base_dir/$vhostname/httpdocs/";
    }

    // validate vhost 
    // not sure that it is good idea ...
    if ( gethostbyname($vhostname) == $vhostname ) {
        logger("[ERROR] Could not create vhost $vhostname : hostname is not valid", LOG_ERR);
        return false;
    }

    if ( mkdir($vhost_path, 0755, 1) ) {
       if ( ! chown($vhost_path, $username) or ! chgrp($vhost_path, $username) ) {
            logger("[ERROR] Could not change owner or group on vhost  directory $vhost_path to user $username", LOG_ERR);
            return false;
        } else {
           if ( ! copy_vhost_files($vhost_path, $username) ) {
                return false;
           } else {
                logger("[OK] Vhost $vhostname for user $username created in ( $vhost_path )", LOG_INFO);
                return true;
           }
       }
    } else {
        logger("[ERROR] Could not create dirs $vhost_path for vhost $vhostname", LOG_ERR);
        return false;
    }
}

function rmdir_recurse ($path) {
    $path = rtrim($path, '/').'/';
    $handle = opendir($path);
    while ( false !== ( $file = readdir($handle))) {
        if ( $file != '.' and $file != '..' ) {
            $fullpath = $path.$file;
            if(is_dir($fullpath)) {
                rmdir_recurse($fullpath);
            } else { 
                if (!unlink($fullpath)) {
                    logger("[ERROR] Could not remove file $fullpath", LOG_ERR);
                    return false;
                }
            }
        }
    }
    closedir($handle);
    if (rmdir($path)) {
        return true;
    } else {
        logger("[ERROR] Could not remove file $fullpath", LOG_ERR);
        return false; 
    }
}

function vhost_del ($username, $vhostname) {

      /*
        This method will delete virtual host for username

        Parameters:
            $username  # string: username should be lowercase
            $vhostname # string: virtual host name (FQDN)

        Return Values:
            Returns TRUE on success or FALSE on failure.
    */   

    $home = check_user($username);
    if (!$home) {
        return false;
    } else {
        $vhost_base_path = "$home/$vhost_base_dir/public_html/$vhostname/";
    }

    if (rmdir_recurse($vhost_base_path)) {
        logger("[OK] Vhost $vhostname for user $username removed  ( $vhost_base_path )", LOG_INFO);
        return true;
    } else {
        logger("[ERROR] Could not remove vhost $vhostname for user $username ( $vhost_base_path )", LOG_ERR);
        return false;
    }

}



switch ($options) { 
    case array_key_exists('i', $options):
       if (!make_home_dir($username)) {
           exit(1);
       } else {
           if (!vhost_add($username, $vhostname)) {
               exit(2);
           }               
       }
       break;
    case array_key_exists('d',$options):
        if (! vhost_del($username, $vhostname) ) {
            exit(1);
        }
        break;
    default:
        if ( ! vhost_add($username, $vhostname) ) {
            exit(1);
        }
};

exit;

