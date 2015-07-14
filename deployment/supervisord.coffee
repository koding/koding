fs            = require 'fs'
{ isAllowed } = require './grouptoenvmapping'

generateMainConf = (supervisorEnvironmentStr ="")->
  """
  [supervisord]
  ; environment variables
  environment=#{supervisorEnvironmentStr}

  [unix_http_server]
  file=/var/run/supervisor.sock                   ; path to your socket file

  [rpcinterface:supervisor]
  supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

  [supervisorctl]
  serverurl=unix:///var/run/supervisor.sock       ; use a unix:// URL  for a unix socket

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

  [inet_http_server]
  port=0.0.0.0:9001
  username=koding
  password=1q2w3e4r

  """

# becareful while editing this function, any change will affect evey worker
generateSupervisorSectionForWorker = (app, options={})->
  section =
    command                 : "command"
    stdout_logfile_maxbytes : "10MB"
    stdout_logfile_backups  : 50
    stderr_logfile          : "/var/log/koding/#{app}.log"
    stdout_logfile          : "/var/log/koding/#{app}.log"
    numprocs                : options.instances or 1
    numprocs_start          : 0
    directory               : "/opt/koding"
    autostart               : yes
    autorestart             : yes
    startsecs               : 10
    startretries            : 5
    stopsignal              : "TERM"
    stopwaitsecs            : 10
    redirect_stderr         : yes
    stdout_logfile          : "/var/log/koding/#{app}.log"
    stdout_logfile_maxbytes : "1MB"
    stdout_logfile_backups  : 10
    stdout_capture_maxbytes : "1MB"

  for key, opt of options.supervisord
    section[key] = opt

  if section.numprocs > 1 and options.ports?
    for key, port of options.ports
      port = "#{port}"
      partialPort = port.substring(0, port.length - 1)
      section.command = section.command.replace new RegExp(port), "#{partialPort}%(process_num)d"

  # %(process_num) must be present within process_name when numprocs > 1
  if section.numprocs > 1
    section.process_name = "%(program_name)s_%(process_num)d"


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
  for name, options of KONFIG.workers  when options.supervisord?.command?
    # some of the locations can be limited to some environments, while creating
    # nginx locations filter with this info
    unless isAllowed options.group, KONFIG.ebEnvName
      continue

    # some of the workers can have multiple command input, one for watch the
    # other on normal. if we want to watch go files use previous one.
    command = options.supervisord.command
    if typeof command is 'object'
      {run, watch} = command
      options.supervisord.command = if KONFIG.runGoWatcher then watch else run

    groupConfigs[options.group]       or= {}
    groupConfigs[options.group][name] or= {}

    conf += generateSupervisorSectionForWorker name, options


  # add group sections
  for group, sections of groupConfigs

    conf += """

    [group:#{group}]
    programs=#{Object.keys(sections).join(",")}
    \n
    """

  conf += """
  [eventlistener:memmon]
  command=memmon -g environment=3072MB -m sysops+supervisord@koding.com
  events=TICK_60

  """

  return conf
