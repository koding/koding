#
#
class traffcalc::service {
        service { "traffcalc":
            ensure     => running,
            hasstatus  => true,
            hasrestart => true,
            enable     => true,
            require    => Class["traffcalc::config"],
        }
}
