define users::useradd ($fullname,$uid,$hash,$key,$key_type) {
    group { "$name":
        ensure => present,
        gid => $uid,
        notify => User[$name],
    }
    
    user { "$name":
        managehome => true, 
        comment => $fullname,
        home => "/home/$name",
        ensure => present,
        shell => "/bin/bash",
        uid => $uid ,
        gid => $uid,
        groups => "wheel",
        password=> $hash,
        require => Group[$name]
    }
    ssh_authorized_key { "$name":
    	ensure => present,
    	key    => $key,
	    type   => $key_type,
	    user   => $name,
    }   
 }
