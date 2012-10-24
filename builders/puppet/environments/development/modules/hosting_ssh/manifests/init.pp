# Class: hosting_sshd
#
#
class hosting_ssh {
    include hosting_ssh::install, hosting_ssh::config, hosting_ssh::service
}
