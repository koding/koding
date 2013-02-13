remote_syslog do
    action :enable
    log_file node["log"]["files"]
end
