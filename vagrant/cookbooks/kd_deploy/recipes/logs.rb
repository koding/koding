remote_syslog do
    enable false
    log_file node["log"]["files"]
end
