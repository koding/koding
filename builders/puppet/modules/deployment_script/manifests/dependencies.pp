# Class: dependencies
#
#
class deployment_script::dependencies {
    package { "python-setuptools":
        ensure => latest,
        notify => [Exec["install_requests"],Exec["install_argparse"]]
    }
}