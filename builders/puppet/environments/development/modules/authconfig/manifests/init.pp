#
#
class authconfig {
    include authconfig::install, authconfig::service,authconfig::config, authconfig::cacertdir_rehash
}
