#$zabbix_user_parameters = []

class zabbix-agent {
    $zabbix_server = "mon.prod.system.aws.koding.com"
    $zabbix_config_dir = "/etc/zabbix"
    $zabbix_agent_conf = "$zabbix_config_dir/zabbix_agent.conf"
    $zabbix_agentd_conf = "$zabbix_config_dir/zabbix_agentd.conf"
    $zabbix_log_dir = "/var/log/zabbix-agent/"
    $zabbix_pid_dir= "/var/run/zabbix-agent/"


    package {
        "zabbix-agent":
            ensure => latest,
            require => Class["yumrepos::zabbixzone"],
            notify => Service["zabbix-agent"]
    }

    user { "zabbix":
        ensure => present,
        groups => adm,
        require => Package["zabbix-agent"];
    }

    file {
        $zabbix_config_dir:
            ensure => directory,
            owner => root,
            group => root,
            mode => 0755,
            require => Package["zabbix-agent"];

        $zabbix_agent_conf:
            owner => root,
            group => root,
            mode => 0644,
            content => template("zabbix-agent/zabbix_agent_conf.erb"),
            require => Package["zabbix-agent"];

        $zabbix_agentd_conf:
            owner => root,
            group => root,
            mode => 0644,
            content => template("zabbix-agent/zabbix_agentd_conf.erb"),
            require => Package["zabbix-agent"];

        $zabbix_log_dir:
            ensure => directory,
            owner => zabbix,
            group => zabbix,
            mode => 0755,
            require => Package["zabbix-agent"];

        $zabbix_pid_dir:
            ensure => directory,
            owner => zabbix,
            group => zabbix,
            mode => 0755,
            require => Package["zabbix-agent"];
    }
    service {
        "zabbix-agent":
            enable => true,
            ensure => running,
            hasstatus => true,
            require => Package["zabbix-agent"]
    }


}
