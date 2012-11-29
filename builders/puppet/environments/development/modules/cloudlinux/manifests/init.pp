# Class: cloudlinux
#
#
class cloudlinux {
    include cloudlinux::cagefs_configs,cloudlinux::pam_lve,cloudlinux::lve,cloudlinux::cagefs_update,cloudlinux::cagefs_enable,cloudlinux::cagefs_remount_all
    include cloudlinux::lvestats
    include cloudlinux::shared_dir
    include cloudlinux::cagefs_minuid

}
