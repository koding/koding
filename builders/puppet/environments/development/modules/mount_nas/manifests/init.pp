# Class: mount_cifs
#
#
class mount_nas {
    
    $nas_host   = 'nas301.service.softlayer.com'
    $nas_user   = 'SL78167-1'
    $nas_pass   = 'XA4VNBnt'
    $nas_mpoint = '/mnt/NAS'
    
    package { "cifs-utils.x86_64":
        ensure => installed,
    }
    
    file { "$nas_mpoint":
        ensure => directory,
        mode => "0700"
    }
    
    mount {"mount_nas":
        atboot  => true,
        ensure  => mounted,
        fstype  => "cifs",
        device  => "//${nas_host}/${nas_user}",
        name    => "$nas_mpoint",
        options => $nodeuser ? {
            true => "user=${nas_user},password=${nas_pass},uid=node,gid=node,noacl,ro",
            false => "user=${nas_user},password=${nas_pass},uid=0,gid=0,noacl,ro",
        },
        remounts => false, 
        require => $nodeuser ? {
            true => [Package["cifs-utils.x86_64"], File["$nas_mpoint"],User['node']],
            false => [Package["cifs-utils.x86_64"], File["$nas_mpoint"]],
        },
    }
    
    file {"/opt/kfmjs":
         ensure  => symlink,
         target  => "${nas_mpoint}/kfmjs",
         require => Mount['mount_nas']
    }

    
}