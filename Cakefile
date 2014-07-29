option '-D', '--debug', 'runs with node, go --debug'
option '-V', '--verbose', 'runs with go --verbose'
option '-C', '--buildClient', 'override buildClient flag with yes'
option '-c', '--configFile [CONFIG]', 'What config file to use.'
option '-v', '--version [VERSION]', 'Switch to a specific version'
option '-a', '--domain [DOMAIN]', 'Pass a domain to the task (right now only broker supports it)'

option '-f', '--file [file]', 'run tests with just one file'
option '-l', '--location [location]', 'run tests with this base url'

option '-t', '--tests', 'require test suite'
option '-s', '--dontBuildSprites', 'dont build sprites'

option '-y', '--yes', 'pass yes to corresponding command'
option '-g', '--evengo', 'pass evengo to corresponding command'

require('coffee-script').register()

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
Watcher            = require 'koding-watcher'

require 'colors'

addFlags = (options)->
  flags  = ""
  flags += " -a #{options.domain}" if options.domain
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

task 'populateNeo4j', "Populate the local Neo4j Database from the config's mongo server", ({configFile})->
  invoke 'deleteNeo4j'

  migrator = "cd go && export GOPATH=`pwd` && go run src/koding/migrators/mongo/mongo2neo4j.go -c #{configFile}"
  processes.exec migrator

task 'deleteNeo4j', "Drop all entries in the local Neo4j database", ({configFile})->
  console.log "This task is hardcoded to delete only Neo running in localhost:7474\n"

  query = """
    curl -X POST -H "Content-Type: application/json" -d '{"query":"start kod=node:koding(\\"id:*\\") match kod-[r]-() delete kod, r"}' "http://localhost:7474/db/data/cypher" && curl -X POST -H "Content-Type: application/json" -d '{"query":"start kod=relationship(*) delete kod;"}' "http://localhost:7474/db/data/cypher" && curl -X POST -H "Content-Type: application/json" -d '{"query":"start kod=node(*) delete kod;"}' "http://localhost:7474/db/data/cypher"
  """
  processes.exec query

task 'compileGo', "Compile the local go binaries", ({configFile})->
  compileGoBinaries configFile,->

task 'webserver', "Run the webserver", ({configFile, tests}) ->
  KONFIG = require('koding-config-manager').load("main.#{configFile}")
  {webserver,sourceServer} = KONFIG

  runServer = (config, port, index) ->
    processes.fork
      name              : "server"
      cmd               : __dirname + "/server/index -c #{config} -p #{port}#{if tests then ' -t' else ''}"
      restart           : yes
      restartTimeout    : 100
      kontrol           :
        enabled         : !!KONFIG.runKontrol
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
          folders   : ['./server', './workers/social']
          onChange  : ->
            processes.kill "server"

task 'socialapi-api', "Run the API of socialapi", (options) ->
  {configFile, tests, version} = options
  KONFIG = require('koding-config-manager').load("main.#{configFile}")
  {socialapi} = KONFIG

  runServer = (config, port, index) ->
    cmdName =  "./go/bin/api -c ./go/src/socialapi/config/#{configFile}.toml -port #{port} -d -v #{version ? 0}"
    console.log "cmdName", cmdName
    processes.spawn
      name              : "socialapiapi"
      cmd               : cmdName
      restart           : yes
      restartTimeout    : 100
      stdout            : process.stdout
      stderr            : process.stderr
      kontrol           :
        enabled         : !!KONFIG.runKontrol
        startMode       : "many"
        registerToProxy : yes
        port            : port
        binary          : hat()

  if socialapi.clusterSize > 1
    webPortStart = socialapi.port
    webPortEnd   = socialapi.port + socialapi.clusterSize - 1
    webPort = [webPortStart..webPortEnd]
  else
    webPort = [socialapi.port]

  webPort.forEach (port, index) ->
    runServer configFile, port, index

task 'socialWorker', "Run the socialWorker", ({configFile}) ->
  KONFIG = require('koding-config-manager').load("main.#{configFile}")
  {social} = KONFIG

  console.log 'CAKEFILE STARTING SOCIAL WORKERS'

  for i in [1..social.numberOfWorkers]
    port = 3029 + i
    kitePort = port + 10000

    processes.fork
      name           : if social.numberOfWorkers is 1 then "social" else "social-#{i}"
      cmd            : __dirname + "/workers/social/index -c #{configFile} -p #{port} --kite-port=#{kitePort}"
      restart        : yes
      restartTimeout : 100
      kontrol        :
        enabled      : !!KONFIG.runKontrol
        startMode    : "many"
        registerToProxy: yes
        proxyName    : 'social'
        port         : port
      # onMessage: (msg) ->
      #   if msg.exiting;
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
    watcher.on 'change', -> console.log 'change happened', arguments

task 'logWorker', "Run the logWorker", ({configFile}) ->
  KONFIG = require('koding-config-manager').load("main.#{configFile}")
  {log} = KONFIG

  for i in [1..log.numberOfWorkers]
    port = 4029 + i

    processes.fork
      name           : if log.numberOfWorkers is 1 then "log" else "log-#{i}"
      cmd            : __dirname + "/workers/log/index -c #{configFile} -p #{port}"
      restart        : yes
      restartTimeout : 100
      kontrol        :
        enabled      : !!KONFIG.runKontrol
        startMode    : "many"
        registerToProxy: yes
        proxyName    : 'log'
        port         : port

  if log.watch is yes
    watcher = new Watcher
      groups :
        log  :
          folders  : ['./workers/log']
          onChange : (path) ->
            if log.numberOfWorkers is 1
              processes.kill "log"
            else
              processes.kill "log-#{i}" for i in [1..log.numberOfWorkers]

    watcher.on 'change', -> console.log 'change happened', arguments

task 'authWorker', "Run the authWorker", ({configFile}) ->
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
        enabled      : !!KONFIG.runKontrol
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

task 'guestCleanerWorker', "Run the guest cleanup worker", ({configFile})->
  config = require('koding-config-manager').load("main.#{configFile}")

  processes.fork
    name           : 'guestCleanerWorker'
    cmd            : "./workers/guestcleaner/index -c #{configFile}"
    restart        : yes
    restartTimeout : 1
    kontrol        :
      enabled      : if config.runKontrol is yes then yes else no
      startMode    : "one"
    verbose        : yes

  watcher = new Watcher
    groups        :
      guestcleaner:
        folders   : ['./workers/guestcleaner']
        onChange  : (path) ->
          processes.kill "guestCleanerWorker"


task 'emailConfirmationCheckerWorker', "Run the email confirmtion worker", ({configFile})->
  config = require('koding-config-manager').load("main.#{configFile}")

  processes.fork
    name           : 'emailConfirmationCheckerWorker'
    cmd            : "./workers/emailconfirmationchecker/index -c #{configFile}"
    restart        : yes
    restartTimeout : 1
    kontrol        :
      enabled      : if config.runKontrol is yes then yes else no
      startMode    : "one"
    verbose        : yes

  watcher = new Watcher
    groups        :
      guestcleaner:
        folders   : ['./workers/emailconfirmationchecker']
        onChange  : (path) ->
          processes.kill "emailConfirmationCheckerWorker"

task 'emailWorker', "Run the email worker", ({configFile})->
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

task 'emailSender', "Run the emailSender", ({configFile})->
  config = require('koding-config-manager').load("main.#{configFile}")

  processes.fork
    name           : 'emailSender'
    cmd            : "./workers/emailsender/index -c #{configFile}"
    restart        : yes
    restartTimeout : 100
    kontrol        :
      enabled      : if config.runKontrol is yes then yes else no
      startMode    : "one"
    verbose        : yes

  watcher = new Watcher
    groups        :
      email       :
        folders   : ['./workers/emailsender']
        onChange  : (path) ->
          processes.kill "emailSender"

task 'goBroker', "Run the goBroker", (options)->
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
      port            : broker.port
      hostname        : options.domain
    verbose           : yes

task 'premiumBroker', "Run the premium broker", (options)->
  {configFile} = options
  config = require('koding-config-manager').load("main.#{configFile}")
  {broker} = config
  uuid = hat()

  processes.spawn
    name              : 'premiumBroker'
    cmd               : "./go/bin/broker -c #{configFile} -u #{uuid} -b premiumBroker #{addFlags options}"
    restart           : yes
    restartTimeout    : 100
    stdout            : process.stdout
    stderr            : process.stderr
    kontrol           :
      enabled         : if config.runKontrol is yes then yes else no
      binary          : uuid
      port            : broker.port
      hostname        : options.domain
    verbose           : yes

task 'goBrokerKite', "Run the goBrokerKite", (options)->
  {configFile} = options
  config = require('koding-config-manager').load("main.#{configFile}")
  {broker} = config
  uuid = hat()

  processes.spawn
    name              : 'brokerKite'
    cmd               : "./go/bin/broker -c #{configFile} -u #{uuid} -b brokerKite #{addFlags options}"
    restart           : yes
    restartTimeout    : 100
    stdout            : process.stdout
    stderr            : process.stderr
    kontrol           :
      enabled         : if config.runKontrol is yes then yes else no
      binary          : uuid
      port            : broker.port
      hostname        : options.domain
    verbose           : yes

task 'premiumBrokerKite', "Run the premium broker kite", (options)->
  {configFile} = options
  config = require('koding-config-manager').load("main.#{configFile}")
  {broker} = config
  uuid = hat()

  processes.spawn
    name              : 'premiumBrokerKite'
    cmd               : "./go/bin/broker -c #{configFile} -u #{uuid} -b premiumBrokerKite #{addFlags options}"
    restart           : yes
    restartTimeout    : 100
    stdout            : process.stdout
    stderr            : process.stderr
    kontrol           :
      enabled         : if config.runKontrol is yes then yes else no
      binary          : uuid
      port            : broker.port
      hostname        : options.domain
    verbose           : yes

task 'rerouting', "Run rerouting", (options)->

  {configFile} = options
  config = require('koding-config-manager').load("main.#{configFile}")

  processes.spawn
    name           : 'rerouting'
    cmd            : "./go/bin/rerouting -c #{configFile}"
    restart        : yes
    restartTimeout : 100
    stdout         : process.stdout
    stderr         : process.stderr
    verbose        : yes
    kontrol        :
      enabled      : if config.runKontrol is yes then yes else no
      startMode    : "one"

# start oskite in /opt/koding/go/src/koding/kites/os because the templates are now inside our oskite repository
task 'osKite', "Run the osKite", ({configFile})->
  processes.spawn
    name  : 'osKite'
    cmd   : if configFile == "vagrant" then "vagrant ssh default -c 'cd /opt/koding; sudo killall -q -KILL os; sudo KITE_HOME=/opt/koding/kite_home/koding /opt/koding/go/bin-vagrant/os -c #{configFile} -r vagrant -t go/src/koding/oskite/files/templates/'" else "./go/bin/os -c #{configFile}"
    restart: no
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'terminalKite', "Run the terminalKite", ({configFile})->
  processes.spawn
    name  : 'terminalKite'
    cmd   : if configFile == "vagrant" then "vagrant ssh default -c 'cd /opt/koding; sudo killall -q -KILL terminal; sudo DNODE_PRINT_RECV=1 KITE_HOME=/opt/koding/kite_home/koding /opt/koding/go/bin-vagrant/terminal -c #{configFile} -r vagrant'" else "./go/bin/terminal -c #{configFile}"
    restart: no
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'proxy', "Run the go-Proxy", ({configFile})->

  processes.spawn
    name  : 'proxy'
    cmd   : if configFile == "vagrant" then "vagrant ssh default -c 'cd /opt/koding; sudo killall -q -KILL vmproxy; sudo ./go/bin-vagrant/vmproxy -c #{configFile}'" else "./go/bin/vmproxy -c #{configFile}"
    restart: no
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

# this is not safe to run multiple version of it
task 'elasticsearchfeeder', "Run the Elastic Search Feeder", (options)->
  {configFile} = options
  config       = require('koding-config-manager').load("main.#{configFile}")
  processes.spawn
    name    : "elasticsearchfeeder"
    cmd     : "./go/bin/elasticsearchfeeder -c #{configFile} #{addFlags options}"
    restart : yes
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes
    kontrol        :
      enabled      : if config.runKontrol is yes then yes else no
      startMode    : "one"

task 'kontrolClient', "Run the kontrolClient", (options) ->
  {configFile} = options
  processes.spawn
    name    : 'kontrolClient'
    cmd     : "./go/bin/kontrolclient -c #{configFile}"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'kontrolProxy', "Run the kontrolProxy", (options) ->
  {configFile} = options
  processes.spawn
    name    : 'kontrolProxy'
    cmd     : "./go/bin/kontrolproxy -c #{configFile}"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'kontrolDaemon', "Run the kontrolDaemon", (options) ->
  {configFile} = options
  processes.spawn
    name    : 'kontrolDaemon'
    cmd     : "./go/bin/kontroldaemon -c #{configFile} #{addFlags options}"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'kontrolApi', "Run the kontrolApi", (options) ->
  {configFile} = options
  processes.spawn
    name    : 'kontrolApi'
    cmd     : "./go/bin/kontrolapi -c #{configFile}"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'kontrolKite', "Run the kontrol kite", (options) ->
  {configFile} = options
  processes.spawn
    name    : 'kontrolKite'
    cmd     : "vagrant ssh default -c 'cd /opt/koding; sudo killall -q -KILL kontrol; sudo KITE_HOME=/opt/koding/kite_home/koding /opt/koding/go/bin-vagrant/kontrol -c #{configFile} -r vagrant'"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'proxyKite', "Run the proxy kite", (options) ->
  {configFile} = options
  processes.spawn
    name    : 'proxyKite'
    cmd     : "vagrant ssh default -c 'cd /opt/koding; sudo killall -q -KILL proxy; sudo KITE_HOME=/opt/koding/kite_home/koding /opt/koding/go/bin-vagrant/proxy -c #{configFile} -r vagrant'"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'regservKite', "Run the regserv kite", (options) ->
  {configFile} = options
  processes.spawn
    name    : 'regservKite'
    cmd     : "vagrant ssh default -c 'cd /opt/koding; sudo killall -q -KILL regserv; sudo KITE_HOME=/opt/koding/kite_home/koding /opt/koding/go/bin-vagrant/regserv -c #{configFile} -r vagrant'"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'checkConfig', "Check the local config files for errors", ({configFile})->
  console.log "[KONFIG CHECK] If you don't see any errors, you're fine."
  require('koding-config-manager').load("main.#{configFile}")
  require('koding-config-manager').load("kite.applications.#{configFile}")
  require('koding-config-manager').load("kite.databases.#{configFile}")

task 'runGraphiteFeeder', "Collect analytics from database and feed to grahpite", ({configFile})->
  console.log "Running Graphite feeder"
  processes.spawn
    name    : 'graphiteFeeder'
    cmd     : "./go/bin/graphitefeeder -c #{configFile}"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

task 'migratePost', "Migrate Posts to JNewStatusUpdate", ({configFile})->
  console.log "Migrating Posts"
  processes.spawn
    name    : 'migratePost'
    cmd     : "./go/bin/posts -c #{configFile}"
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

run =({configFile})->
  process.stdout.setMaxListeners 100
  process.stderr.setMaxListeners 100

  config = require('koding-config-manager').load("main.#{configFile}")

  compileGoBinaries configFile, ->
    invoke 'kontrolDaemon'                    if config.runKontrol
    invoke 'kontrolApi'                       if config.runKontrol

    invoke 'kontrolKite'                      if config.runKontrol
    invoke 'proxyKite'                        if config.runKontrol
    invoke 'regservKite'                      if config.runKontrol

    invoke 'goBroker'                         if config.runGoBroker
    invoke 'goBrokerKite'                     if config.runGoBrokerKite
    invoke 'premiumBroker'                    if config.runPremiumBroker
    invoke 'premiumBrokerKite'                if config.runPremiumBrokerKite
    invoke 'osKite'                           if config.runOsKite
    invoke 'terminalKite'                     if config.runTerminalKite
    invoke 'rerouting'                        if config.runRerouting
    invoke 'proxy'                            if config.runProxy
    invoke 'elasticsearchfeeder'              if config.elasticSearch.enabled
    invoke 'authWorker'                       if config.authWorker
    invoke 'guestCleanerWorker'               if config.guestCleanerWorker.enabled
    invoke 'emailConfirmationCheckerWorker'   if config.emailConfirmationCheckerWorker.enabled
    invoke 'socialWorker'
    invoke 'emailWorker'                      if config.emailWorker?.run is yes
    invoke 'emailSender'                      if config.emailSender?.run is yes
    invoke 'addTagCategories'
    invoke 'webserver'
    invoke 'logWorker'                        if config.log.runWorker

task 'importDB', (options) ->
  if options.configFile is 'vagrant'
    (spawn 'bash', ['./vagrant/import.sh'])
      .stdout
        .on 'data', (it) ->
          console.log "#{it}"
        .on 'end', ->
          console.log "Import is finished!".green
          process.exit()
  else
    console.error "You should only run this task with -c vagrant".red

task 'run', (options)->
  {configFile} = options
  options.configFile = "vagrant" if configFile in ["",undefined,"undefined"]
  KONFIG = config = require('koding-config-manager').load("main.#{configFile}")

  if "vagrant" is options.configFile
    (spawn 'bash', ['./vagrant/needimport.sh'])
      .stdout.on 'data', (it) ->
        if "#{it}" is '1\n'
          console.error "You need to run cake -c vagrant importDB".red
          process.exit()

  oldIndex = nodePath.join __dirname, "website/index.html"
  if fs.existsSync oldIndex
    fs.unlinkSync oldIndex

  config.buildClient = yes if options.buildClient

  queue = []
  if config.buildClient is yes
    queue.push ->

      buildMethod =
        if options.dontBuildSprites
        then 'buildClient'
        else 'buildSprites'

      (new (require('./Builder')))[buildMethod] options
      queue.next()
  queue.push -> run options
  daisy queue

task 'buildTests', "Build the client-side tests", (options) ->

task 'killGoProcesses', " Kill hanging go processes", (options) ->
  command = "kill -9 `ps -ef | grep go/bin | grep -v grep | awk '{print $2}'`"
  exec command

task 'buildClient', "Build the static web pages for webserver", (options)->
  buildMethod =
    if options.dontBuildSprites
    then 'buildClient'
    else 'buildSprites'

  (new (require('./Builder')))[buildMethod] options

task 'deleteCache', "Delete the local webserver cache", (options)->
  exec "rm -rf #{__dirname}/.build",->
    console.log "Cache is pruned."

task 'cleanup', "Removes every cache, and file which is not committed yet",
(options)->
  sure = if options.yes then "" else "-n"
  evengo = if options.evengo then "" else "-e go"
  exec "git clean -d -f #{sure} -x -e .vagrant -e node_modules -e node_modules_koding #{evengo}", (err, res)->
    if res isnt ''
      console.log "\n\n#{res}"
      unless options.yes
        console.log "If you are sure to remove these files run:\n\n  $ cake --yes cleanup \n"
        console.warn "Doing `vagrant halt` is recommended before cleanup!"
      else
        console.log "All remaining files removed, it's a new era for you!\n"
    else
      console.log "Everything seems fine, nothing to remove."

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

task 'runExternals', "runs externals kite which imports info about github, will be used to show suggested tags, users to follow etc.", (options)->
  {configFile} = options
  config = require('koding-config-manager').load("main.#{configFile}")

  processes.spawn
    name              : 'externals'
    cmd               : "./go/bin/externals -c #{configFile}"
    restart           : yes
    restartTimeout    : 100
    stdout            : process.stdout
    stderr            : process.stderr
    kontrol           :
      enabled         : if config.runKontrol is yes then yes else no
    verbose           : yes

task 'importPaymentData', "creates default payment data", (options)->
  {configFile} = options
  config = require('koding-config-manager').load("main.#{configFile}")

  processes.spawn
    cmd            : "node ./workers/productimport/index -c #{configFile}"
    name           : 'importPaymentData'
    stdout         : process.stdout
    stderr         : process.stderr
    kontrol        :
      enabled      : if config.runKontrol is yes then yes else no
      startMode    : "one"
    verbose        : yes

# ------------------- TEST STUFF --------------------------

# ----- run all tests ----
task 'test-all', 'Runs functional test suite', (options)->
  which = (paths)->
    for path in paths
      return path if fs.existsSync(path)

  # do we have the virtualenv ???
  pip = which ['./env/bin/pip', '/usr/local/bin/pip', '/usr/bin/pip']
  unless pip
    console.error "please install pip with \n brew install python --framework"
    return

  cmd = "sudo #{pip} install --src=/tmp/.koding-qa -e 'git+ssh://git@git.sj.koding.com/qa.git@master#egg=testengine'"
  exec cmd, (err, stdout, stderr)->
    if err
      log.error """
        TestEngine installation error, please copy and paste the output below
        and send to QA
      """
      log.info "cmd:", cmd
      log.info err
      log.info stdout
      log.info stderr
      return

    testEngine = which ['./env/bin/testengine_run', '/usr/local/bin/testengine_run']
    if not testEngine
      throw "TestEngine installation error"
    configFile = options.configFile or 'vagrant'

    args = ['-p', './tests', '-c', configFile]
    if options.file
      args.push '-f', options.file
    if options.location
      args.push '-l', options.location

    testProcess = spawn testEngine, args

    testProcess.stderr.on 'data', (data)->
      process.stdout.write data.toString()
    testProcess.stdout.on 'data', (data)->
      process.stdout.write data.toString()
    testProcess.on 'close', (code)->
      process.exit code

# ------------ OTHER LESS IMPORTANT STUFF ---------------------#

task 'parseAnalyzedCss','Shows the output of analyzeCss in a nice format',(options)->

  fs.readFile "/tmp/identicals.css",'utf8',(err,data)->
    stuff = JSON.parse data

    log.info stuff

task 'analyzeCss','Checks lengthy css and suggests improvements',(options)->

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
    for line in arr
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



{installSikuli, runSikuli} = require "./cake_tasks/sikuli"
task 'installSikuli', "Downloads and installs Sikuli", -> installSikuli()
task 'runTest', "Opens http://localhost:3020 and runs tests", -> runSikuli()
