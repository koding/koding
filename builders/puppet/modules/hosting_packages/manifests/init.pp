# Class: hosting_packages
#
#
class hosting_packages {
    
    include hosting_packages::ruby  
    include hosting_packages::python
    include hosting_packages::perl 
    include hosting_packages::archives 
    include hosting_packages::vcs 
    include hosting_packages::fun 
    include hosting_packages::mysql
    include hosting_packages::mongo
    include hosting_packages::java
    include hosting_packages::php
    include hosting_packages::ftp
    include hosting_packages::editors
    include hosting_packages::tools
    include hosting_packages::compilers
    include hosting_packages::erlang
    include hosting_packages::mounters
    include hosting_packages::terminal
    include hosting_packages::dotcloud

}
