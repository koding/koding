generateMainConf = (supervisorEnvironmentStr ="")->
  """
  [supervisord]
  ; environment variables
  environment=#{supervisorEnvironmentStr}

  logfile=/var/log/supervisord/supervisord.log    ; supervisord log file
  logfile_maxbytes=50MB                           ; maximum size of logfile before rotation
  logfile_backups=10                              ; number of backed up logfiles
  loglevel=error                                  ; info, debug, warn, trace
  pidfile=/var/run/supervisord.pid                ; pidfile location
  nodaemon=false                                  ; run supervisord as a daemon
  minfds=10000                                    ; number of startup file descriptors
  minprocs=200                                    ; number of process descriptors
  user=root                                       ; default user
  childlogdir=/var/log/supervisord/               ; where child log files will live
  \n
  """

# becareful while editing this function, any change will affect evey worker
generateSupervisorSectionForWorker = (app, options={})->
  section =
    command                 : "command"
    stdout_logfile_maxbytes : "10MB"
    stdout_logfile_backups  : 50
    stderr_logfile          : "/var/log/koding/#{app}.log"
    stdout_logfile          : "/var/log/koding/#{app}.log"
    numprocs                : 1
    directory               : "/opt/koding"
    autostart               : yes
    autorestart             : yes
    startsecs               : 10
    startretries            : 3
    stopsignal              : "TERM"
    stopwaitsecs            : 10
    redirect_stderr         : yes
    stdout_logfile          : "/var/log/koding/#{app}.log"
    stdout_logfile_maxbytes : "1MB"
    stdout_logfile_backups  : 10
    stdout_capture_maxbytes : "1MB"

  for key, opt of options
    section[key] = opt

  supervisordSection = "\n[program:#{app}]\n"
  for key, val of section
    # longest supervisord conf's length is 31
    space = new Array(32-key.length).join(" ")
    supervisordSection += "#{key}#{space} = #{val}\n"

  return supervisordSection



module.exports.create = (KONFIG)->
  # create environment variables for the supervisor
  # we can remove this later?
  supervisorEnvironmentStr = ""
  supervisorEnvironmentStr += "#{key}='#{val}'," for key,val of KONFIG.ENV


  # create supervisord main config
  conf = generateMainConf supervisorEnvironmentStr

  groupConfigs = {}

  # for every worker create their section configs under group name
  for name, options of KONFIG.workers

    groupConfigs[options.group]       or= {}
    groupConfigs[options.group][name] or= {}


    conf += generateSupervisorSectionForWorker name, options.supervisord


  # add group sections
  for group, sections of groupConfigs

    conf += """

    [group:#{group}]
    programs=#{Object.keys(sections).join(",")}
    \n
    """
  console.log conf
  return conf
