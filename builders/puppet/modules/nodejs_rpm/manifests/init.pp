# Class: nodejs_rpm
#
#
class nodejs_rpm {
    include nodejs_rpm::yumrepo, nodejs_rpm::install
}