# Class: sshd
#
#
class ssh {
    include ssh::install, ssh::config, ssh::service
}