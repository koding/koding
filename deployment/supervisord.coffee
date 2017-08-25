_  = require 'lodash'
fs = require 'fs'

{ isAllowed } = require './grouptoenvmapping'
{ generateCountlySupervisord } = require './countly/generateConfig'

generateMainConf = ->

  '''
  [supervisord]
  pidfile=%(ENV_KONFIG_SUPERVISORD_RUNDIR)s/supervisord.pid
  logfile=%(ENV_KONFIG_SUPERVISORD_LOGDIR)s/supervisord.log
  childlogdir=%(ENV_KONFIG_SUPERVISORD_LOGDIR)s/

  ; number of startup file descriptors
  minfds=%(ENV_KONFIG_SUPERVISORD_MINFDS)s

  ; number of process descriptors
  minprocs=%(ENV_KONFIG_SUPERVISORD_MINPROCS)s

  logfile_maxbytes=50MB                           ; maximum size of logfile before rotation
  logfile_backups=10                              ; number of backed up logfiles
  loglevel=error                                  ; info, debug, warn, trace

  nodaemon=false                                  ; run supervisord as a daemon
  user=root                                       ; default user

  [unix_http_server]
  file=%(ENV_KONFIG_SUPERVISORD_UNIX_HTTP_SERVER_FILE)s

  [rpcinterface:supervisor]
  supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

  [supervisorctl]
  serverurl=unix://%(ENV_KONFIG_SUPERVISORD_UNIX_HTTP_SERVER_FILE)s

  [inet_http_server]
  port=0.0.0.0:9001
  username=koding
  password=1q2w3e4r

  '''

# becareful while editing this function, any change will affect every worker
generateWorkerSection = (app, options = {}) ->

  { supervisord: section } = options

  _.defaults section, {
    numprocs                : options.instances or 1
    numprocs_start          : 0
    directory               : '%(ENV_KONFIG_PROJECTROOT)s'
    autostart               : yes
    autorestart             : yes
    startsecs               : 10
    startretries            : 5
    stopsignal              : 'TERM'
    stopwaitsecs            : 10
    stopasgroup             : yes
    killasgroup             : yes
    redirect_stderr         : yes
    stdout_logfile          : "%(ENV_KONFIG_SUPERVISORD_LOGDIR)s/#{app}.log"
    stdout_logfile_maxbytes : '1MB'
    stdout_logfile_backups  : 10
    stdout_capture_maxbytes : '1MB'
    stderr_logfile          : "%(ENV_KONFIG_SUPERVISORD_LOGDIR)s/#{app}.log"
  }

  if section.numprocs > 1 and options.ports?
    for key, port of options.ports
      port = "#{port}"
      partialPort = port.substring(0, port.length - 1)
      section.command = section.command.replace new RegExp(port), "#{partialPort}%(process_num)d"

    if instanceArg = options.instanceAsArgument
      section.command = "#{section.command} #{instanceArg} %(process_num)d"

  # %(process_num) must be present within process_name when numprocs > 1
  if section.numprocs > 1
    section.process_name = '%(program_name)s_%(process_num)d'

  supervisordSection = "\n[program:#{app}]\n"
  for key, val of section
    # longest supervisord conf's length is 31
    space = new Array(32 - key.length).join(' ')
    supervisordSection += "#{key}#{space} = #{val}\n"

  return supervisordSection


generateMemmonSection = (config) ->

  { limit, email } = config
  limit or= '2048MB'

  """
  [eventlistener:memmon]
  command=memmon -a #{limit}
  events=TICK_60
  """


module.exports.create = (KONFIG) ->
  # create supervisord main config
  conf = generateMainConf()

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
      { run, watch } = command
      options.supervisord.command = if KONFIG.runGoWatcher then watch else run

    groupConfigs[options.group]       or= {}
    groupConfigs[options.group][name] or= {}

    conf += generateWorkerSection name, options

  # add group sections
  for group, sections of groupConfigs

    conf += """

    [group:#{group}]
    programs=#{Object.keys(sections).join(",")}

    """

  { memmon } = KONFIG.supervisord
  conf += generateMemmonSection memmon  if memmon
  conf += generateCountlySupervisord KONFIG

  return conf
