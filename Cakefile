option '-d', '--database [DB]', 'specify the db to connect to [local|vpn|wan]'
option '-D', '--debug', 'runs with node --debug'
option '-P', '--pistachios', "as a post-processing step, it compiles any pistachios inline"
option '-b', '--runBroker', 'should it run the broker locally?'
option '-C', '--buildClient', 'override buildClient flag with yes'
option '-B', '--configureBroker', 'should it configure the broker?'
option '-c', '--configFile [CONFIG]', 'What config file to use.'
<<<<<<< Updated upstream
option '-u', '--username [USER]', 'User for AWS deployment or user which will be added to VPN'
=======
option '-u', '--username [USER]', 'User for with execution rights (probably your local username)'
option '-n', '--name [NAME]', 'The name of the new VPN user'
>>>>>>> Stashed changes
option '-e', '--email [EMail]', 'EMail address to send the new VPN config to'

{argv} = require 'optimist'
{spawn, exec} = require 'child_process'
# mix koding node modules into node_modules
# exec "ln -sf `pwd`/node_modules_koding/* `pwd`/node_modules",(a,b,c)->
#   # can't run the program if this fails,
#   if a or b or c
#     console.log "Couldn't mix node_modules_koding into node_modules, exiting. (failed command: ln -sf `pwd`/node_modules_koding/* `pwd`/node_modules)"
#     process.exit(0)

ProgressBar = require './builders/node_modules/progress'
Builder     = require './builders/Builder'
S3          = require './builders/s3'
# log4js      = require "./builders/node_modules/log4js"
# log         = log4js.getLogger("[Main]")

log =
  info  : console.log
  error : console.log
  debug : console.log
  warn  : console.log

prompt    = require './builders/node_modules/prompt'
hat       = require "./builders/node_modules/hat"
mkdirp    = require './builders/node_modules/mkdirp'
commander = require './builders/node_modules/commander'

sourceCodeAnalyzer = new (require "./builders/SourceCodeAnalyzer.coffee")
processes          = new (require "processes") main : true
closureCompile     = require 'koding-closure-compiler'
{daisy}            = require 'sinkrow'
fs                 = require "fs"
http               = require 'http'
url                = require 'url'
nodePath           = require 'path'
Watcher            = require "koding-watcher"
KODING_CAKE = './node_modules/koding-cake/bin/cake'

# create required folders
mkdirp.sync "./.build/.cache"

compilePistachios = require 'pistachio-compiler'

compileGoBinaries = (configFile,callback)->

  ###
  #   TBD - CHECK FOR ERRORS
  ###

  compileGo = require('koding-config-manager').load("main.#{configFile}").compileGo
  if compileGo
    processes.spawn
      name: 'build'
      cmd : './go/build.sh'
      stdout : process.stdout
      stderr : process.stderr
      verbose : yes
      onExit :->
        callback null
  else
    callback null

task 'compileGo',({configFile})->
  compileGoBinaries configFile,->

task 'runKites', ({configFile})->

  compileGoBinaries configFile,->
    invoke 'sharedHostingKite'
    invoke 'databasesKite'
    invoke 'applicationsKite'
    invoke 'webtermKite'

task 'webtermKite',({configFile})->
  configFile = "dev" if configFile in ["",undefined,"undefined"]
  processes.spawn
    name    : 'webterm'
    cmd     : __dirname+"/kites/webterm -c #{configFile}"
    restart : yes
    verbose : yes

task 'sharedHostingKite',({configFile})->
  {numberOfWorkers} = require('koding-config-manager').load("kite.sharedHosting.#{configFile}")
  numberOfWorkers ?= config.numberOfWorkers ? 1

  for _, i in Array +numberOfWorkers
    processes.fork
      name    : "sharedHosting"
      cmd     : __dirname+"/kites/sharedHosting/index -c #{configFile} --sharedHosting"
      restart : yes

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
  {webserver} = KONFIG

  runServer = (config, port) ->
    processes.fork
      name            : 'server'
      cmd             : __dirname + "/server/index -c #{config} -p #{port}"
      restart         : yes
      restartInterval : 100

  webPort = webserver.port
  webPort = [webPort] unless Array.isArray webPort
  webPort.forEach (port) ->
    runServer configFile, port
    return # MORE THAN 1 PORT IS NOT ALLOWED. CONFUSES PROCESS MODULE.

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
      name  : "socialWorker-#{i}"
      cmd   : __dirname + "/workers/social/index -c #{configFile}"
      restart : yes
      restartInterval : 100
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
            processes.kill "socialWorker-#{i}" for i in [1..social.numberOfWorkers]


task 'authWorker',({configFile}) ->
  config = require('koding-config-manager').load("main.#{configFile}").authWorker
  numberOfWorkers = if config.numberOfWorkers then config.numberOfWorkers else 1

  for _, i in Array +numberOfWorkers
    processes.fork
      name  : "authWorker-#{i}"
      cmd   : __dirname+"/workers/auth/index -c #{configFile}"
      restart : yes
      restartInterval : 1000

  if config.watch is yes
    watcher = new Watcher
      groups        :
        auth        :
          folders   : ['./workers/auth']
          onChange  : (path) ->
            processes.kill "authWorker-#{i}" for _, i in Array +numberOfWorkers

task 'guestCleanup',({configFile})->

  processes.fork
    name  : 'guestCleanup'
    cmd   : "./workers/guestcleanup/index -c #{configFile}"
    restart: yes
    restartInterval: 100

task 'emailWorker',({configFile})->

  processes.fork
    name            : 'emailWorker'
    cmd             : "./workers/emailnotifications/index -c #{configFile}"
    restart         : yes
    restartInterval : 100

  watcher = new Watcher
    groups        :
      email       :
        folders   : ['./workers/emailnotifications']
        onChange  : (path) ->
          processes.kill "emailWorker"

task 'goBroker',({configFile})->

  processes.spawn
    name  : 'goBroker'
    cmd   : "./go/bin/broker -c #{configFile}"
    restart: yes
    restartInterval: 100
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

  watchBroker = (url, interval, kills, failedReqs) ->
    kills =  if kills then kills else 0
    failedReqs = if failedReqs then failedReqs else 0

    setTimeout ->
      http.get url, (res) ->
        watchBroker(url, interval)
      .on 'error', (e) ->
        failedReqs++
        console.log("WARN: Broker did not respond", failedReqs, "times.")
        if failedReqs > 1 # account for random errors, manual restarts
          kills++
          processes.killAllChildren process.pid, ->
            console.log("WARN: Killed broker #{kills} times since it stopped responding.")
        watchBroker(url, interval, kills, failedReqs)
    , interval

  config = require('koding-config-manager').load("main.#{configFile}")
  watchGoBroker = config.watchGoBroker
  sockjs_url = "http://localhost:8008/subscribe" # config.client.runtimeOptions.broker.sockJS
  if watchGoBroker is yes
    watchBroker(sockjs_url, 10000)

task 'libratoWorker',({configFile})->

  processes.fork
    name  : 'libratoWorker'
    cmd   : "#{KODING_CAKE} ./workers/librato -c #{configFile} run"
    restart: yes
    restartInterval: 100
    verbose: yes

task 'cacheWorker',({configFile})->
  KONFIG = require('koding-config-manager').load("main.#{configFile}")
  {cacheWorker} = KONFIG

  processes.fork
    name            : 'cacheWorker'
    cmd             : "./workers/cacher/index -c #{configFile}"
    restart         : yes
    restartInterval : 100

  if cacheWorker.watch is yes
    watcher = new Watcher
      groups        :
        server      :
          folders   : ['./workers/cacher']
          onChange  : ->
            processes.kill "cacheWorker"


task 'checkConfig',({configFile})->
  console.log "[KONFIG CHECK] If you don't see any errors, you're fine."
  require('koding-config-manager').load("main.#{configFile}")
  require('koding-config-manager').load("kite.applications.#{configFile}")
  require('koding-config-manager').load("kite.databases.#{configFile}")
  require('koding-config-manager').load("kite.sharedHosting.#{configFile}")


run =({configFile})->
  config = require('koding-config-manager').load("main.#{configFile}")

  compileGoBinaries configFile,->
    invoke 'goBroker'       if config.runGoBroker
    invoke 'authWorker'     if config.authWorker
    invoke 'guestCleanup'   if config.guests
    invoke 'libratoWorker'  if config.librato?.push
    invoke 'cacheWorker'    if config.cacheWorker?.run is yes
    invoke 'compileGo'      if config.compileGo
    invoke 'socialWorker'
    invoke 'emailWorker'    if config.emailWorker?.run is yes
    invoke 'webserver'


task 'run', (options)->
  {configFile} = options
  options.configFile = "dev" if configFile in ["",undefined,"undefined"]
  KONFIG = config = require('koding-config-manager').load("main.#{configFile}")

  config.buildClient = yes if options.buildClient

  queue = []
  if config.buildClient is yes
    queue.push -> buildClient options, -> queue.next()
  queue.push -> run options
  daisy queue

clientFileMiddleware  = (options, commandLineOptions, code, callback)->
  # console.log 'args', options
  # here you can change the content of kd.js before it's written to it's final file.
  # options is the cakefile options, opt is where file is passed in.
  {libraries,kdjs}      = code
  {minify, pistachios}  = options


  kdjs =  "var KD = {};\n" +
          "KD.config = "+JSON.stringify(options.runtimeOptions)+";\n"+
          kdjs

  if commandLineOptions.pistachios or pistachios
    console.log "[PISTACHIO] compiler started."
    kdjs = compilePistachios kdjs
    console.log "[PISTACHIO] compiler finished."

  js = "#{libraries}#{kdjs}"

  if minify
    closureCompile js,(err,data)->
      unless err
        callback null, data
      else
        # if error just provide the original file. so site isn't down until this is fixed.
        callback null, js
  else
    callback null, js

buildClient =(options, callback=->)->

  config = require('koding-config-manager').load("main.#{options.configFile}")

  builderOptions =
    config      : config.client
    commandLine : options

  builder = new Builder builderOptions,clientFileMiddleware,""


  builder.watcher.initialize()

  builder.watcher.on "initDidComplete",(changes)->
    builder.buildClient options,()->
      builder.buildCss {},()->
        builder.buildIndex {},()->
          if config.client.watch is yes
            log.info "started watching for changes.."
            builder.watcher.start 1000
          else
            log.info "Done building client"
          callback null

  builder.watcher.on "changeDidHappen",(changes)->
    # log.info changes
    if changes.Client? and not changes.StylusFiles
      builder.buildClient options,()->
        builder.buildIndex {},()->
          # log.debug "client build is complete"

    if changes.Client?.StylusFiles?
      builder.buildCss {}, ->
        builder.buildIndex {}, ->
    if changes.Cake
      log.debug "Cakefile changed.."
      builder.watcher.reInitialize()

  builder.watcher.on "CoffeeScript Compile Error",(filePath,error)->
    log.error "CoffeeScript ERROR, last good known version of #{filePath} is compiled. Please fix this error and recompile. #{error}"
    spawn.apply null, ["say",["coffee script error"]]

task 'buildClient', (options)->
  buildClient options




task 'deleteCache',(options)->
  exec "rm -rf #{__dirname}/.build/.cache",->
    console.log "Cache is pruned."


task 'deploy', (options) ->
  {configFile,username} = options
  {aws} = config = require('koding-config-manager').load("main.#{configFile}")

  exec "git branch | grep '*' | awk -F ' ' '{print $2}'", (error, stdout, stderr) ->
    git_branch = stdout
    username ?= process.env['USER']

    proc = spawn 'builders/aws/cloud-formation/pushDev.py', ['-a', aws.key, '-s', aws.secret, '-u', username, '-g', git_branch]
    proc.stdout.on 'data', (data) ->
      console.log data.toString().trim()
    proc.stderr.on 'data', (data) ->
      console.log data.toString().trim()

task 'destroy', (options) ->
  {configFile,username} = options
  {aws} = config = require('koding-config-manager').load("main.#{configFile}")

  username ?= process.env['USER']

  proc = spawn 'builders/aws/cloud-formation/pushDev.py', ['-a', aws.key, '-s', aws.secret, '-u', username, '-X']
  proc.stdout.on 'data', (data) ->
    console.log data.toString().trim()
  proc.stderr.on 'data', (data) ->
    console.log data.toString().trim()

task 'deploy-info', (options) ->
  {configFile,username} = options
  {aws} = config = require('koding-config-manager').load("main.#{configFile}")

  username ?= process.env['USER']

  proc = spawn 'builders/aws/cloud-formation/pushDev.py', ['-a', aws.key, '-s', aws.secret, '-u', username, '-i']
  proc.stdout.on 'data', (data) ->
    console.log data.toString().trim()
  proc.stderr.on 'data', (data) ->
    console.log data.toString().trim()

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

  # cmd = "ssh cblum@gateway.dev.service.aws.koding.com && sudo su && source /etc/openvpn/easy-rsa/vars && /etc/openvpn/easy-rsa/pkitool #{username}"
  cmd = "ssh #{username}@10.116.118.191 -- sudo /root/addVPNuser.sh #{name} #{email}"
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
  configFile = normalizeConfigPath options.configFile
  config = require configFile
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

task 'uploadToS3','',(options)->
  S3 = new require("./build/s3")
  s3 = new S3
    key     : "AKIAJO74E23N33AFRGAQ"
    secret  : "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"
    bucket  : "koding"

  s3.putFile targetPaths.client,"js/kd.js",()->
  s3.putFile targetPaths.css,"css/kd.css",()->
  s3.putFile targetPaths.index,"index.html",()->
