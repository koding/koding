# Class: munin
#
#
class munin {
    include munin::install,munin::config,munin::service
}