option '-d', '--database [DB]', 'specify the db to connect to [local|vpn|wan]'
option '-D', '--debug', 'runs with node, go --debug'
option '-V', '--verbose', 'runs with go --verbose'
option '-P', '--pistachios', "as a post-processing step, it compiles any pistachios inline"
option '-b', '--runBroker', 'should it run the broker locally?'
option '-C', '--buildClient', 'override buildClient flag with yes'
option '-B', '--configureBroker', 'should it configure the broker?'
option '-c', '--configFile [CONFIG]', 'What config file to use.'
option '-u', '--username [USER]', 'User for with execution rights (probably your local username)'
option '-n', '--name [NAME]', 'The name of the new VPN user'
option '-e', '--email [EMail]', 'EMail address to send the new VPN config to'
option '-t', '--type [TYPE]', 'AWS machine type'
option '-v', '--version [VERSION]', 'Switch to a specific version'

{spawn, exec} = require 'child_process'

log =
  info  : console.log
  error : console.log
  debug : console.log
  warn  : console.log

processes          = new (require "processes") main : true
{daisy}            = require 'sinkrow'
fs                 = require "fs"
http               = require 'http'
hat                = require 'hat'
url                = require 'url'
nodePath           = require 'path'
portchecker        = require 'portchecker'
Watcher            = require "koding-watcher"

addFlags = (options)->
  flags  = ""
  flags += " -d" if options.debug
  flags += " -v" if options.verbose
  return flags

compileGoBinaries = (configFile,callback)->

  ###
  #   TBD - CHECK FOR ERRORS
  ###

  compileGo = require('koding-config-manager').load("main.#{configFile}").compileGo
  if compileGo
    processes.spawn
      name: 'build go'
      cmd : './go/build.sh'
      stdout : process.stdout
      stderr : process.stderr
      verbose : yes
      onExit :->
        if configFile == "vagrant"
          processes.spawn
            name: 'build go in vagrant'
            cmd : 'vagrant ssh default --command "/opt/koding/go/build.sh bin-vagrant"'
            stdout : process.stdout
            stderr : process.stderr
            verbose : yes
            onExit :->
              callback null
        else
          callback null
  else
    callback null

initializeDB = do ->

  { exec } = (require 'child_process')

  commands = [
    'mongo koding2 --eval "db.dropDatabase()"'
    'mongorestore /opt/koding/dump/koding2'
    'mongo koding2 --eval "db.jCounters.count() ||'+
    ' db.jCounters.save({ \\"_id\\" : \\"vm_ip\\", \\"v\\" : 176161307 });"'
  ]

  inVagrant = (cmd) -> "vagrant ssh default -c '#{cmd}'"

  (err, out) ->
    console.error err  if err
    console.log out    if out
    if (command = do commands.shift)?
      exec inVagrant(command), initializeDB


task 'initializeDB', ->
  console.warn "FIXME: this is a temporary kludge"
  initializeDB()

task 'compileGo',({configFile})->
  compileGoBinaries configFile,->

task 'databasesKite',({configFile})->
  processes.fork
    name    : "databases"
    cmd     : __dirname+"/kites/databases/index -c #{configFile} --databases"
    restart : yes

task 'applicationsKite',({configFile})->
  processes.fork
    name    : "applications"
    cmd     : __dirname+"/kites/applications/index -c #{configFile} --applications"
    restart : yes

task 'webserver', ({configFile}) ->
  KONFIG = require('koding-config-manager').load("main.#{configFile}")
  {webserver,sourceServer} = KONFIG

  runServer = (config, port, index) ->
    processes.fork
      name              : "server"
      cmd               : __dirname + "/server/index -c #{config} -p #{port}"
      restart           : yes
      restartTimeout    : 100
      kontrol           :
        enabled         : if KONFIG.runKontrol is yes then yes else no
        startMode       : "many"
        registerToProxy : yes
        port            : port

  if webserver.clusterSize > 1
    webPortStart = webserver.port
    webPortEnd   = webserver.port + webserver.clusterSize - 1
    webPort = [webPortStart..webPortEnd]
  else
    webPort = [webserver.port]

  webPort.forEach (port, index) ->
    runServer configFile, port, index

  if sourceServer?.enabled
    processes.fork
      name           : 'sourceserver'
      cmd            : __dirname + "/server/lib/source-server -c #{configFile} -p #{sourceServer.port}"
      restart        : yes
      restartTimeout : 100

  if webserver.watch is yes
    watcher = new Watcher
      groups        :
        server      :
          folders   : ['./server']
          onChange  : ->
            processes.kill "server"

task 'socialWorker', ({configFile}) ->
  KONFIG = require('koding-config-manager').load("main.#{configFile}")
  {social} = KONFIG

  for i in [1..social.numberOfWorkers]
    processes.fork
      name           : if social.numberOfWorkers is 1 then "social" else "social-#{i}"
      cmd            : __dirname + "/workers/social/index -c #{configFile}"
      restart        : yes
      restartTimeout : 100
      kontrol        :
        enabled      : if KONFIG.runKontrol is yes then yes else no
        startMode    : "many"
      # onMessage: (msg) ->
      #   if msg.exiting
      #     exitingProcesses[msg.pid] = yes
      #     runProcess(0)
      # onExit: (pid, name) ->
      #   unless exitingProcesses[pid]
      #     runProcess(0)
      #   else
      #     delete exitingProcesses[pid]

  if social.watch?
    watcher = new Watcher
      groups   :
        social   :
          folders   : ['./workers/social']
          onChange  : (path) ->
            if social.numberOfWorkers is 1
              processes.kill "social"
            else
              processes.kill "social-#{i}" for i in [1..social.numberOfWorkers]


task 'authWorker',({configFile}) ->
  KONFIG = require('koding-config-manager').load("main.#{configFile}")
  config = require('koding-config-manager').load("main.#{configFile}").authWorker
  numberOfWorkers = if config.numberOfWorkers then config.numberOfWorkers else 1

  for i in [1..numberOfWorkers]
    processes.fork
      name  		 : if numberOfWorkers is 1 then "auth" else "auth-#{i}"
      cmd   		 : __dirname+"/workers/auth/index -c #{configFile}"
      restart 		 : yes
      restartTimeout : 1000
      kontrol        :
        enabled      : if KONFIG.runKontrol is yes then yes else no
        startMode    : "many"
      verbose        : yes

  if config.watch is yes
    watcher = new Watcher
      groups        :
        auth        :
          folders   : ['./workers/auth']
          onChange  : (path) ->
            if numberOfWorkers is 1
              processes.kill "auth"
            else
              processes.kill "auth-#{i}" for i in [1..numberOfWorkers]

task 'guestCleanup',({configFile})->
  config = require('koding-config-manager').load("main.#{configFile}")

  processes.fork
    name           : 'guestCleanup'
    cmd            : "./workers/guestcleanup/index -c #{configFile}"
    restart        : yes
    restartTimeout : 100
    kontrol        :
      enabled      : if config.runKontrol is yes then yes else no
      startMode    : "one"
    verbose        : yes

task 'emailWorker',({configFile})->
  config = require('koding-config-manager').load("main.#{configFile}")

  processes.fork
    name           : 'email'
    cmd            : "./workers/emailnotifications/index -c #{configFile}"
    restart        : yes
    restartTimeout : 100
    kontrol        :
      enabled      : if config.runKontrol is yes then yes else no
      startMode    : "one"
    verbose        : yes

  watcher = new Watcher
    groups        :
      email       :
        folders   : ['./workers/emailnotifications']
        onChange  : (path) ->
          processes.kill "emailWorker"

task 'emailSender',({configFile})->

  processes.fork
    name           : 'emailSender'
    cmd            : "./workers/emailsender/index -c #{configFile}"
    restart        : yes
    restartTimeout : 100

  watcher = new Watcher
    groups        :
      email       :
        folders   : ['./workers/emailsender']
        onChange  : (path) ->
          processes.kill "emailSender"

task 'goBroker',(options)->
  {configFile} = options
  config = require('koding-config-manager').load("main.#{configFile}")
  {broker} = config
  uuid = hat()

  processes.spawn
    name              : 'broker'
    cmd               : "./go/bin/broker -c #{configFile} -u #{uuid} #{addFlags options}"
    restart           : yes
    restartTimeout    : 100
    stdout            : process.stdout
    stderr            : process.stderr
    kontrol           :
      enabled         : if config.runKontrol is yes then yes else no
      binary          : uuid
    verbose           : yes

task 'rerouting',(options)->

  {configFile} = options

  processes.spawn
    name           : 'rerouting'
    cmd            : "./go/bin/rerouting -c #{configFile}"
    restart        : yes
    restartTimeout : 100
    stdout         : process.stdout
    stderr         : process.stderr
    verbose        : yes

task 'osKite',({configFile})->

  processes.spawn
    name  : 'osKite'
    cmd   : if configFile == "vagrant" then "vagrant ssh default -c 'cd /opt/koding; sudo killall -q -KILL os; sudo ./go/bin-vagrant/os -c #{configFile}'" else "./go/bin/os -c #{configFile}"
    restart: no
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'proxy',({configFile})->

  processes.spawn
    name  : 'proxy'
    cmd   : if configFile == "vagrant" then "vagrant ssh default -c 'cd /opt/koding; sudo killall -q -KILL vmproxy; sudo ./go/bin-vagrant/vmproxy -c #{configFile}'" else "./go/bin/vmproxy -c #{configFile}"
    restart: no
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'libratoWorker',({configFile})->

  processes.fork
    name           : 'librato'
    cmd            : "./node_modules/koding-cake/bin/cake ./workers/librato -c #{configFile} run"
    restart        : yes
    restartTimeout : 100
    kontrol        :
      enabled      : if config.runKontrol is yes then yes else no
      startMode    : "one"
    verbose        : yes

task 'cacheWorker',({configFile})->
  KONFIG = require('koding-config-manager').load("main.#{configFile}")
  {cacheWorker} = KONFIG

  processes.fork
    name           : 'cache'
    cmd            : "./workers/cacher/index -c #{configFile}"
    restart        : yes
    restartTimeout : 100
    kontrol        :
      enabled      : if KONFIG.runKontrol is yes then yes else no
      startMode    : "one"

  if cacheWorker.watch is yes
    watcher = new Watcher
      groups        :
        server      :
          folders   : ['./workers/cacher']
          onChange  : ->
            processes.kill "cacheWorker"


task 'kontrolCli',({configFile}) ->
  processes.fork
    name : "kontrol"
    cmd  : "./node_modules/kontrol -c #{configFile}"

task 'kontrolClient',(options) ->
  {configFile} = options
  processes.spawn
    name    : 'kontrolClient'
    cmd     : "./go/bin/kontrolclient -c #{configFile}"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'kontrolProxy',(options) ->
  {configFile} = options
  processes.spawn
    name    : 'kontrolProxy'
    cmd     : "./go/bin/kontrolproxy -c #{configFile}"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'kontrolRabbit',(options) ->
  {configFile} = options
  processes.spawn
    name    : 'kontrolRabbit'
    cmd     : "./go/bin/kontrolrabbit -c #{configFile}"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'kontrolDaemon',(options) ->
  {configFile} = options
  processes.spawn
    name    : 'kontrolDaemon'
    cmd     : "./go/bin/kontroldaemon -c #{configFile} #{addFlags options}"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'kontrolApi',(options) ->
  {configFile} = options
  processes.spawn
    name    : 'kontrolApi'
    cmd     : "./go/bin/kontrolapi -c #{configFile}"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'kontrol',(options) ->
  {configFile} = options
  invoke 'kontrolDaemon'
  invoke 'kontrolApi'

task 'checkConfig',({configFile})->
  console.log "[KONFIG CHECK] If you don't see any errors, you're fine."
  require('koding-config-manager').load("main.#{configFile}")
  require('koding-config-manager').load("kite.applications.#{configFile}")
  require('koding-config-manager').load("kite.databases.#{configFile}")


run =({configFile})->
  config = require('koding-config-manager').load("main.#{configFile}")

  compileGoBinaries configFile, ->
    invoke 'goBroker'       if config.runGoBroker
    invoke 'osKite'         if config.runOsKite
    invoke 'rerouting'      if config.runRerouting
    invoke 'proxy'          if config.runProxy
    invoke 'authWorker'     if config.authWorker
    invoke 'guestCleanup'   if config.guests
    invoke 'libratoWorker'  if config.librato?.push
    invoke 'cacheWorker'    if config.cacheWorker?.run is yes
    invoke 'socialWorker'
    invoke 'emailWorker'    if config.emailWorker?.run is yes
    invoke 'emailSender'    if config.emailSender?.run is yes
    invoke 'webserver'


task 'run', (options)->
  {configFile} = options
  options.configFile = "dev" if configFile in ["",undefined,"undefined"]
  KONFIG = config = require('koding-config-manager').load("main.#{configFile}")

  oldIndex = nodePath.join __dirname, "website/index.html"
  if fs.existsSync oldIndex
    fs.unlinkSync oldIndex

  config.buildClient = yes if options.buildClient

  queue = []
  if config.buildClient is yes
    queue.push ->
      (new (require('./Builder'))).buildClient options
      queue.next()
  queue.push -> run options
  daisy queue


task 'accounting', (options)->

  {configFile} = options
  options.configFile = "dev" if configFile in ["",undefined,"undefined"]
  KONFIG = config = require('koding-config-manager').load("main.#{configFile}")

  processes.fork
    name    : "accounting"
    cmd     : __dirname + "/workers/accounting/index -c #{configFile}"
    verbose: yes


task 'buildClient', (options)->
  (new (require('./Builder'))).buildClient options

task 'release',(options)->
  # Release and shared data directories
  dataDir         = nodePath.join __dirname, "../koding-data"
  releaseDir      = nodePath.join __dirname, "../koding-release"

  unless fs.existsSync dataDir
    fs.mkdirSync dataDir
  unless fs.existsSync releaseDir
    fs.mkdirSync releaseDir

  # Temporary file for runnings bash scripts
  tmpFile         = "/tmp/#{Date.now()}"

  # Get ready for new release
  config          = require('koding-config-manager').load("main.#{options.configFile}")
  version         = parseInt config.version

  buildDir        = "#{releaseDir}/#{version}"
  dynCfgPath      = "#{buildDir}/config/.dynamic-config.json"

  # Starting ports
  webPort = config.haproxy.webPort + (version % 10) * 100 + 1

  newRelease = ->
    # Get previous dynamic config
    if fs.existsSync dataDir+"/dynamic-config.json"
      conf = JSON.parse fs.readFileSync dataDir+"/dynamic-config.json"
    else
      conf = JSON.parse fs.readFileSync __dirname+"/config/.dynamic-config.json"

    # Build dynamic config
    conf.webInternalPort   = webPort
    conf.webClusterSize    = config.webserver.clusterSize
    conf.webPort           = config.haproxy.webPort
    unless conf.releaseDir == buildDir
      conf.oldReleaseDir   = conf.releaseDir
    conf.releaseDir        = buildDir

    # Install new release
    bash = """
      echo Preparing new release...
      rm -rf #{buildDir}
      mkdir -p #{buildDir}
      cp -R . #{buildDir}
      cd #{buildDir}
      npm install --unsafe-perm
      echo
    """

    fs.writeFileSync tmpFile,bash

    processes.exec "bash #{tmpFile}",()->
      # Save config to release directory
      fs.writeFileSync dynCfgPath,JSON.stringify conf

      # Show release information
      console.log "Version        : " + version
      console.log "Release Folder : " + buildDir
      console.log "Web Port       : " + webPort

  # Deploy new release if necessary
  if fs.existsSync dynCfgPath
    console.log "Version #{version} is already deployed. Increasing release number."
    oldConf = JSON.parse fs.readFileSync dynCfgPath
    version++
    fs.writeFileSync 'VERSION', version
    buildDir        = "#{releaseDir}/#{version}"
    # proxyCfgPath    = "#{buildDir}/config/.haproxy.cfg"
    dynCfgPath      = "#{buildDir}/config/.dynamic-config.json"
    webPort = config.haproxy.webPort + (version % 10) * 100 + 1

  console.log "Deploying version #{version} to #{buildDir}"
  newRelease()

task 'switchProxy', (options) ->
  releaseDir      = nodePath.join __dirname, "../koding-release"
  dataDir         = nodePath.join __dirname, "../koding-data"

  dynCfgPath      = "#{dataDir}/dynamic-config.json"
  proxyCfgPath    = "#{dataDir}/haproxy.cfg"
  haPidFile       = "#{dataDir}/haproxy.pid"

  unless options.version
    console.log "Available versions:"
    for version in fs.readdirSync releaseDir
      vConf = JSON.parse fs.readFileSync "#{releaseDir}/#{version}/config/.dynamic-config.json"
      console.log "  #{version} : port #{vConf.webInternalPort}"
    console.log ""
    console.log "Use cake -v [VERSION] switchProxy"
    process.exit()

  newDynCfg   = "#{releaseDir}/#{options.version}/config/.dynamic-config.json"

  unless fs.existsSync newDynCfg
    console.log "No such version."
    console.log "Drop -v argument to see deployed versions."
    process.exit()

  conf        = JSON.parse fs.readFileSync newDynCfg

  updateProxy = ->
    haproxyCfg = """
      global
          daemon
          maxconn 512

      defaults
          mode http
          timeout connect 5000ms
          timeout client 50000ms
          timeout server 50000ms

      listen stats :1235
          mode http
          stats enable
          stats hide-version
          stats realm 'Koding'
          stats uri /
          stats auth koding:vv8ogdHLaFA2MQA

      listen http-in
          bind *:#{conf.webPort}
          option httpchk GET / HTTP/1.0

    """

    ports = [conf.webInternalPort..conf.webInternalPort+conf.webClusterSize-1]
    for port, i in ports
      haproxyCfg += "    server server#{i} 127.0.0.1:#{port} maxconn 128 check port #{port}\n"

    # Save proxy configuration to release directory
    fs.writeFileSync proxyCfgPath, haproxyCfg

    if fs.existsSync dynCfgPath
      fs.unlinkSync dynCfgPath
    fs.symlinkSync newDynCfg, dynCfgPath
    fs.readFile haPidFile, (err, data) ->
      unless err
        haProxyBash = "haproxy -f #{proxyCfgPath} -p #{haPidFile} -st #{data.toString().trim()}"
      else
        haProxyBash = "haproxy -f #{proxyCfgPath} -p #{haPidFile}"

      processes.exec haProxyBash, ()->
        console.log ""
        console.log "Done."

  # Update proxy configuration
  tries = 10
  tryProxy = ->
    portchecker.isOpen conf.webInternalPort, '0.0.0.0', (webOpen, port, host) ->
      console.log "Checking if new release is up and running..."
      if webOpen
        updateProxy()
      else
        tries--
        if tries > 0
          setTimeout tryProxy, 5000
        else
          console.log ""
          console.log "This release is not running: #{conf.releaseDir}"
          console.log "CD into #{conf.releaseDir}/ and execute cake run"
          console.log ""
          console.log ""

  tryProxy()

task 'deleteCache',(options)->
  exec "rm -rf #{__dirname}/.build",->
    console.log "Cache is pruned."

task 'aws', (options) ->
  {configFile,type} = options
  {aws} = config = require('koding-config-manager').load("main.#{configFile}")

  # List available machines
  unless type
    console.log "Machine types:"
    for filename in fs.readdirSync './aws'
      if filename.match /\.coffee$/
        console.log "  #{filename.slice(0, -7)}"
    console.log ""
    console.log "Run: cake -c #{configFile} -t <type> aws"
    process.exit()

  console.log "Using ./aws/#{type}.coffee file as template"
  console.log ""

  # AWS Utils
  awsUtil = require 'koding-aws'
  awsUtil.init aws

  # Machine template
  awsTemplate = require "./aws/#{type}"

  # Build template
  awsUtil.buildTemplate awsTemplate, (err, templateData) ->
    unless err
      console.log "Template is ready. Running instance..."

      awsUtil.startEC2 templateData, (err, ecData) ->
        unless err
          console.log "EC2 instance is ready:"
          console.log ecData
          console.log ""

task 'buildAll',"build chris's modules", ->

  buildables = ["pistachio","scrubber","sinkrow","mongoop","koding-dnode-protocol","jspath","bongo-client"]
  # log.info "building..."
  b = (next) ->
    cmd = "cd ./node_modules_koding/#{buildables[next]} && cake build"
    log.info "building... cmd: #{cmd}"
    processes.run
      cmd     : cmd
      log     : yes       # or provide a path for log file
      restart : no        # or provide a function
      onExit  : (id)->
        # log.debug "pid.#{id} said: 'im done.'[#{cmd}]"
        if next is buildables.length-1
          log.info "build complete. now running cake build."
          # process.exit()
          invoke "build"
        else
          b next+1
  b 0


task 'resetGuests', (options)->
  configFile = normalizeConfigPath options.configFile
  {resetGuests} = require './workers/guestcleanup/guestinit'
  resetGuests configFile

task 'addVPNuser', "adds a VPN user, use with -n, -u and -e", (options) ->
  {name, username, email} = options
  if name in ["",undefined,"undefined"]
    log.warn "name not set! Use -n flag"
    return false
  if username in ["",undefined,"undefined"]
    log.warn "username not set! Use -u flag"
    return false
  if email in ["",undefined,"undefined"]
    log.warn "email not set! Use -e flag"
    return false

  cmd = "ssh #{username}@vpn.in.koding.com -- sudo /root/addVPNuser.sh #{name} #{email}"
  log.info "executing... cmd: #{cmd}"
  processes.spawn
    name: 'addUser'
    cmd : cmd
    stdout : process.stdout
    stderr : process.stderr
    verbose : yes
    onExit : null





































# ------------ OTHER LESS IMPORTANT STUFF ---------------------#


task 'parseAnalyzedCss','',(options)->

  fs.readFile "/tmp/identicals.css",'utf8',(err,data)->
    stuff = JSON.parse data

    log.info stuff

task 'analyzeCss','',(options)->

  config = require('koding-config-manager').load("main.#{options.configFile}")
  compareArrays = (arrA, arrB) ->
    return false if arrA?.length isnt arrB?.length
    if arrA?.slice()?.sort?
      cA = arrA.slice().sort().join("")
      cB = arrB.slice().sort().join("")
      cA is cB
    else
      # log.error "something wrong with this pair of arrays",arrA,arrB



  fs.readFile config.client.css,'utf8',(err,data)->
    br = 'body,html'+(data.split "body,html")[1]
    # log.debug arr
    arr = br.split "\n"
    css = {}
    for own line in arr
      ln = line.split "{"
      ln1 = ln[1]?.substr 0,ln[1].length-1
      css[ln[0]] = ln1?.split ";"
      # unless ln1? then log.error line
    log.info "getting in"
    # fs.writeFileSync "/tmp/f.css", JSON.stringify css,"utf8"
    # log.info "written."
    identicals = {}
    counter=
      chars : 0
      fns   : 0
    for own name,selector of css
      for own name2,selector2 of css
        fl = firstLetter = name.substr(0,1)
        unless fl is "@" or fl is " " or fl is "{" or fl is "}"
          res = compareArrays selector2,selector
          if res and name isnt name2
            unless identicals[name2]?[name]?
              # log.info fl
              log.info "#{name} --------- is identical to -----------> #{name2}"
              identicals[name] ?= {}
              identicals[name][name2] = 1
              identicals[name].__content = selector
              counter.chars+=selector.join(";").length
              counter.fns++
          # log.debug selector,selector2
    fs.writeFileSync "/tmp/identicals.css", JSON.stringify identicals,"utf8"
    log.info "------------------"
    log.info "log file is at /tmp/identicals.css"
    log.info "#{counter.fns} selectors contain identical CSS properties"
    log.info "possible savings:",Math.floor(counter.chars/1024)+" kbytes"
    log.info "this tool works only if u did 'cake -usd vpn beta' before running analyzeCss."
