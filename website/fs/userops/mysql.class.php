<?php

class Mysql {

    /*
     Example:
        $my = new Mysql('mysql1.beta.service.aws.koding.com');
        $my->create_koding_db($db,$user,$pass);
        $my->change_password($user,$new_pass);
        $my->get_database_size($dbname);
        $my->delete_koding_db($db,$user);
    */   

    private $alert_mail = 'aleksey@koding.com';

    private $root_user = 'admin';
    private $root_pass = '3dkmcmfjghghg';
    private $mysql_link;

    function __construct($server) {
        openlog("[PHP Mysql]",LOG_NDELAY, LOG_LOCAL4);

        $this->mysql_link = mysql_pconnect($server, $this->root_user, $this->root_pass);
        if (! $this->mysql_link) {
            $err = "[ERROR] Could not connect to mysql server $server: " . mysql_error($this->mysql_link);
            $this->logger($err,LOG_ERR);            
            die($err);
        } 
    }

    private function logger ($message, $priority) {
            $message = str_replace("\r\n",'',$message);
            echo ($message."\n");
            if ( $priority == LOG_ERR ) { 
                mail($this->alert_mail,"mysql error!",$message);
            }
            syslog($priority, $message);
    }

    private function run_sql($escaped_sql) {
        if ( mysql_query($escaped_sql, $this->mysql_link)) {
            $this->logger("[OK]  '$escaped_sql' executed ", LOG_INFO);
            return true;
        } else {
            $this->logger("[ERROR] Could not execute '$escaped_sql': " . mysql_error($this->mysql_link), LOG_ERR);
            return false;
        }
    }


    private function create_db($dbname) {

        if ($this->run_sql("CREATE DATABASE " . mysql_real_escape_string($dbname))) return true; else return false;
    }

    private function delete_db($dbname) {
        if ($this->run_sql("DROP DATABASE " . mysql_real_escape_string($dbname))) return true; else return false;
    }

    private function delete_db_user($username) {
        if ($this->run_sql("DROP USER " . mysql_real_escape_string($username) . "@'%'")) return true; else return false;
    }

    private function create_db_user($username, $password, $dbname) {
        $username = mysql_real_escape_string($username);
        $password = mysql_real_escape_string($password);
        $dbname = mysql_real_escape_string($dbname);

        $user_check = "SELECT user FROM mysql.user WHERE user = '$username'";
        if ( $result = mysql_query($user_check, $this->mysql_link)) {
            $row = mysql_fetch_assoc($result);
            if ($row['user'] == $username) {
                $this->logger("[ERROR] Could not create user $username : user already exists", LOG_ERR);
                return false;
            } else { 
                $grant = "GRANT ALL ON $dbname.* TO $username@'%' IDENTIFIED BY '$password'";
                if ($this->run_sql($grant)) return true; else return false;
            }
        } else {
            $this->logger("[ERROR] Could not execute '$user_check': " . mysql_error($this->mysql_link), LOG_ERR);
            return false;
        }   

    }


    public function get_database_size($dbname) {
         /*
            This method will retrieve data size in database

            Parameters:
                $dbname  # string: database name

            Return Values:
                Returns database size in KB on success or FALSE on failure.
        */

        $dbname = mysql_real_escape_string($dbname);

        $get_size = "SHOW TABLE STATUS FROM ${dbname}";
        if ( $result = mysql_query($get_size, $this->mysql_link) ) {
           $size = 0;
           while ( $row = mysql_fetch_assoc($result) ) {
               #print_r($row);
               $size = $size + $row['Index_length'] + $row['Data_length'];
           }
           return round($size/1024);
        } else {
           $this->logger("[ERROR] Could not execute '$get_size' on db '$dbname': " . mysql_error($this->mysql_link), LOG_ERR);
           return false;
        }

   }


    public function change_password($username,$new_pass) {
         /*
            This method will change user's password for database

            Parameters:
                $username # string: user's name
                $new_pass # string: new password in plain text

            Return Values:
                Returns TRUE on success or FALSE on failure.
        */

        $username = mysql_real_escape_string($username);
        $new_pass = mysql_real_escape_string($new_pass);
        $change_pw = "SET PASSWORD FOR '${username}'@'%' = PASSWORD('${new_pass}')";
        if ($this->run_sql($change_pw)) return true; else return false;
    }

    public function create_koding_db($dbname, $username, $password) {
        /*
            This method will create database with username and password

            Parameters:
                $dbname   # string: database name
                $username # string: user's name
                $password # string: password in plain text

            Return Values:
                Returns an array(username => $username,
                                hostname  => $hostname,
                                dbname => $dbname,
                                password => $password,
                           ) on success
                or FALSE on failure.
        */


        if (! $this->create_db_user($username,$password,$dbname) ) {
            return false;
        } else {
            if ( ! $this->create_db($dbname) ) {
                return false;
            } else {
                $result = array('username' => $username,
                                'hostname' => 'localhost',
                                'dbname' => $dbname,
                                'password' => $password,
                );
                return $result;
            }
        }
    }


    public function delete_koding_db($dbname, $username) {

         /*
            This method will delete user's database and user from mysq.user

            Parameters:
                $dbname  # string: database name
                $username # string: user's name

            Return Values:
                Returns TRUE on success or FALSE on failure.
        */

        if (! $this->delete_db($dbname) ) {
            return false;
        } else {
            if ( ! $this->delete_db_user($username) ) {
                return false;
            } else {
                return true;
            }
        }

    }
}
