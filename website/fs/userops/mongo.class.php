<?php

class KDmongo {
    

    /*
    Example :
        $moo = new KDmongo('mongo1.beta.service.aws.koding.com');
        $moo->create_db($dbname, $username, $password);
        $moo->get_database_size($dbname);
        $moo->change_password($dbname, $username, $new_pass);
        $moo->delete_db($dbname);
    */

    private $alert_mail = 'aleksey@koding.com';

    private $root_user = 'admin';
    private $root_pass = '22t78skhdlksaje1';
    private $mongo_link;
    private $db_link;


    function __construct($server) {
        openlog("[PHP Mongo]",LOG_NDELAY, LOG_LOCAL4);

        $conn_string = "mongodb://$this->root_user:$this->root_pass@${server}";

        try {
            $this->mongo_link = new Mongo($conn_string, array("persist" => "x"));
        } catch  (MongoConnectionException $e) {
            $err = "[ERROR] Could not connect to mongo server $server: " . $e->getMessage();
            $this->logger($err,LOG_ERR);            
            die($err);

        }

    }

    private function logger ($message, $priority) {
        $message = str_replace("\r\n",'',$message);
        echo ($message."\n");
        if ( $priority == LOG_ERR ) { 
            mail($this->alert_mail,"mongo error!",$message);
        }
        syslog($priority, $message);
    }

    private function check_if_db_exists ($dbname) {
        foreach ( $this->mongo_link->listDBs()["databases"] as $db ) {
            if ( $db["name"] == $dbname ) return true; else false;
        }
    }

    public function create_db ($dbname,$username,$password) {
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


        $dbname = (string) $dbname;
        $username = (string) $username;
        $password = (string) $password;

        if ( $this->check_if_db_exists($dbname) ) {
            $this->logger("[ERROR] Could not create db for user $username - database with name '$dbname' already exists", LOG_ERR);
            return false;
        } 
        
        try {
            $this->db = $this->mongo_link->selectDB($dbname);
        } catch ( InvalidArgumentException $e ) {
            $this->logger("[ERROR] could not select db '$dbname': ". $e->getMessage(), LOG_ERR);
            return false;
        }

        $coll = $this->db->selectCollection("system.users");
        try {
            // safe insert
            $coll->insert(array('user' => $username, 'pwd' => md5($username . ":mongo:" . $password), 'readOnly' => false), true);
            $this->logger("[OK] Database '$dbname' for user '$username' created", LOG_INFO); 
            $result = array('username' => $username,
                            'hostname' => 'localhost',
                            'dbname' => $dbname,
                            'password' => $password,
                     );
            return $result;

        } catch ( MongoCursorException $e ) {
            $this->logger("[ERROR] Could not insert user ${username} into db $dbname: ". $e->getMessage(), LOG_ERR);
            return false;
        }
    }
    
    public function change_password($dbname,$username,$new_pass) {

        /*
            This method will change user's password for database

            Parameters:
                $dbname   # string: database name
                $username # string: user's name
                $new_pass # string: new password in plain text

            Return Values:
                Returns TRUE on success or FALSE on failure.
        */

        $dbname = (string) $dbname;
        $username = (string) $username;
        $new_pass = (string) $new_pass;

        if ( ! $this->check_if_db_exists($dbname) ) {
            $this->logger("[ERROR] Could not change password for $username - database with name '$dbname' does not exists", LOG_ERR);
            return false;
        } 

         try {
            $this->db = $this->mongo_link->selectDB($dbname);
        } catch ( InvalidArgumentException $e ) {
            $this->logger("[ERROR] could not select db '$dbname': ". $e->getMessage(), LOG_ERR);
            return false;
        }

        $coll = $this->db->selectCollection("system.users");
        $user = $coll->findOne(array('user' => $username));

        if (!$user) {
            $this->logger("[ERROR] can't find user '$username' in db '$dbname'", LOG_ERR);
            return false;
        }

        try {
            $user['pwd'] = md5($username . ":mongo:" . $new_pass); 

            $coll->update(
                   array('user' => $username),$user,
                   array("upsert" => false, "safe" => true)
            );
            $this->logger("[OK] Password for user '$username' in db '$dbname' changed", LOG_INFO); 
            return true;
        } catch ( MongoCursorException $e ) {
            $this->logger("[ERROR] Could not r ${username} into db $dbname: ". $e->getMessage(), LOG_ERR);
            return false;
        }


    }
    
    public function delete_db($dbname) {
         /*
            This method will delete user's database

            Parameters:
                $dbname  # string: database name

            Return Values:
                Returns TRUE on success or FALSE on failure.
        */
 
        $dbname = (string) $dbname;
        if ( ! $this->check_if_db_exists($dbname) ) {
            $this->logger("[ERROR] Could not delete database '$dbname' - database does not exists", LOG_ERR);
            return false;
        } 
  
        try {
            $this->db = $this->mongo_link->selectDB($dbname);
        } catch ( InvalidArgumentException $e ) {
            $this->logger("[ERROR] could not select db '$dbname': ". $e->getMessage(), LOG_ERR);
            return false;
        }

        if ( $dbname == "admin" ) {
            $this->logger("[ERROR] someone tried to delete admin database! ", LOG_ERR);
            return false;
        } else {
            $response = $this->db->drop();
            if ($response["ok"]) {
                $this->logger("[OK] Database $dbname successfully deleted", LOG_INFO);
                return true;
            } else {
                $this->logger("[ERROR] something wrong with db delete operation on db '$dbname'");
                return false;
           }
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
 
        $dbname = (string) $dbname;
        if ( ! $this->check_if_db_exists($dbname) ) {
            $this->logger("[ERROR] Could not database size for '$dbname' - database does not exists", LOG_ERR);
            return false;
        }

        try {
            $this->db = $this->mongo_link->selectDB($dbname);
        } catch ( InvalidArgumentException $e ) {
            $this->logger("[ERROR] could not select db '$dbname': ". $e->getMessage(), LOG_ERR);
            return false;
        }

        
        $res = $this->db->command(array('dbStats' => 1,'scale' => 1024));
        if ($res['ok']){
            $this->logger("[OK] Database size for '$dbname' is ${res['dataSize']}", LOG_INFO);
            return $res['dataSize'];
        } else {
            $this->logger("[ERROR] Could not get data size for database '$dbname': ${res['errmsg']}", LOG_INFO); 
            return false;
        }

    }
   
    
}

