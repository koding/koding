class deploy_from_s3::yumrepo {
    
    yumrepo { "deploy_from_s3":
        baseurl => "http://s3tools.org/repo/RHEL_6/",
        descr => "Tools for managing Amazon S3 - Simple Storage Service (RHEL_6)",
        enabled => "1",
        gpgcheck => "1",
        gpgkey => "http://s3tools.org/repo/RHEL_6/repodata/repomd.xml.key",
    }
}
