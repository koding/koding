remote_syslog do
    enable true
    log_file node["log"]["files"]
end
