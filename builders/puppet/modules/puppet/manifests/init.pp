# Class: puppet
#
#
class puppet {
    include puppet::install, puppet::service
}
