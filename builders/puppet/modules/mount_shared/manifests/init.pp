#
#
class mount_shared {
    
    $nas_host   = "nfs0.dev.service.aws.koding.com"
    $nas_resource = "/export/shared"
    $nas_mpoint = '/Shared'
    
    file { "$nas_mpoint":
        ensure => directory,
        mode => "0755"
    }
    
    mount {"mount_nas":
        atboot  => true,
        ensure  => mounted,
        fstype  => "nfs4",
        options => "proto=tcp,port=2049",
        device  => "${nas_host}:${nas_resource}",
        name    => "$nas_mpoint",
        remounts => true, 
        require => Class["nfs_server"],
    }
}
