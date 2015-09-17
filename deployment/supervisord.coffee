fs            = require 'fs'
{ isAllowed } = require './grouptoenvmapping'

generateMainConf = (KONFIG) ->

  environment = ""
  environment += "#{key}='#{val}'," for key,val of KONFIG.ENV

  {supervisord} = KONFIG

  {
    logdir
    rundir
    minfds
    minprocs
    unix_http_server
  } = supervisord

  """
  [supervisord]
  ; environment variables
  environment=#{environment}

  pidfile=#{rundir}/supervisord.pid

  logfile=#{logdir}/supervisord.log
  childlogdir=#{logdir}/

  ; number of startup file descriptors
  minfds=#{minfds}

  ; number of process descriptors
  minprocs=#{minprocs}

  logfile_maxbytes=50MB                           ; maximum size of logfile before rotation
  logfile_backups=10                              ; number of backed up logfiles
  loglevel=error                                  ; info, debug, warn, trace

  nodaemon=false                                  ; run supervisord as a daemon
  user=root                                       ; default user

  [unix_http_server]
  file=#{unix_http_server.file}

  [rpcinterface:supervisor]
  supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

  [supervisorctl]
  serverurl=unix://#{unix_http_server.file}       ; use a unix:// URL  for a unix socket

  [inet_http_server]
  port=0.0.0.0:9001
  username=koding
  password=1q2w3e4r

  """

# becareful while editing this function, any change will affect every worker
generateWorkerSection = (app, options={}, KONFIG) ->

  {projectRoot} = KONFIG
  {supervisord: {logdir}} = KONFIG

  section =
    command                 : "command"
    stdout_logfile_maxbytes : "10MB"
    stdout_logfile_backups  : 50
    stderr_logfile          : "#{logdir}/#{app}.log"
    stdout_logfile          : "#{logdir}/#{app}.log"
    numprocs                : options.instances or 1
    numprocs_start          : 0
    directory               : projectRoot
    autostart               : yes
    autorestart             : yes
    startsecs               : 10
    startretries            : 5
    stopsignal              : "TERM"
    stopwaitsecs            : 10
    redirect_stderr         : yes
    stdout_logfile          : "#{logdir}/#{app}.log"
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


generateMemmonSection = (config) ->

  {limit, email} = config
  limit or= "2048MB"

  """
  [eventlistener:memmon]
  command=memmon -a #{limit}
  events=TICK_60
  """


module.exports.create = (KONFIG)->
  # create supervisord main config
  conf = generateMainConf KONFIG

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

    conf += generateWorkerSection name, options, KONFIG


  # add group sections
  for group, sections of groupConfigs

    conf += """

    [group:#{group}]
    programs=#{Object.keys(sections).join(",")}
    \n
    """

  {memmon} = KONFIG.supervisord
  conf += generateMemmonSection memmon  if memmon

  return conf
