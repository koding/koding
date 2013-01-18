class nfs_server {

    include nfs_server::install
    include nfs_server::service
    include nfs_server::config
    include nfs_server::exports

}

