# Class: dblvm
#
#
class hosting_mysql_lvm {
    include hosting_mysql_lvm::create_lvm, hosting_mysql_lvm::mount
}