
class cloudlinux::shared_dir {
    file { '/Shared':
        ensure => 'directory',
        mode => 0751,
        owner => 'root',
        group => 'root',
    }
}
