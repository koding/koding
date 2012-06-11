# Class: hosting_packages
#
#
class hosting_packages {
    
    include hosting_packages::ruby, hosting_packages::python, hosting_packages::perl, hosting_packages::archives, hosting_packages::vcs,hosting_packages::fun, hosting_packages::mysql
    include hosting_packages::mongo
    include hosting_packages::java
    include hosting_packages::php
    include hosting_packages::ftp
    include hosting_packages::editors

}
