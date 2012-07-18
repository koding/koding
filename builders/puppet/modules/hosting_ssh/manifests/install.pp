class hosting_ssh::install {
  package { ["openssh-server",'openssh-clients','openssh']:
    ensure => present,
  }
}
