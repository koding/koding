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
option '-r', '--region [REGION]', 'region flag'


require('coffee-script').register()



task 'guestCleanerWorker', "Run the guest cleanup worker", (options)-> guestCleanerWorker options
task 'emailConfirmationCheckerWorker', "Run the email confirmtion worker", (options)-> emailConfirmationCheckerWorker options
task 'sitemapGeneratorWorker', "Generate the sitemap worker", (options)-> sitemapGeneratorWorker options
task 'socialWorker', "Run the socialWorker", (options) -> socialWorker options
task 'kloudKite',"run kloud kite", (options) -> kloudKite options
task 'compileGo', "Compile the local go binaries", (options)-> compileGoBinaries options
task 'webserver', "Run the webserver", (options) -> webserver options
task 'logWorker', "Run the logWorker", (options) -> logWorker options
task 'authWorker', "Run the authWorker", (options) -> authWorker options
task 'goBroker', "Run the goBroker", (options)-> goBroker options
task 'emailWorker', "Run the email worker", (options)-> emailWorker options
task 'emailSender', "Run the emailSender", (options)-> emailSender options
task 'premiumBroker', "Run the premium broker", (options)-> premiumBroker options
task 'goBrokerKite', "Run the goBrokerKite", (options)-> goBrokerKite options
task 'premiumBrokerKite', "Run the premium broker kite", (options)-> premiumBrokerKite options
task 'rerouting', "Run rerouting", (options)-> rerouting options
task 'userpresence', "Run userpresence", (options)-> userpresence options
task 'elasticsearchfeeder', "Run the Elastic Search Feeder", (options)-> elasticsearchfeeder options
task 'kontrolClient', "Run the kontrolClient", (options) -> kontrolClient options
task 'kontrolProxy', "Run the kontrolProxy", (options) -> kontrolProxy options
task 'kontrolDaemon', "Run the kontrolDaemon", (options) -> kontrolDaemon options
task 'kontrolApi', "Run the kontrolApi", (options) -> kontrolApi options
task 'kontrolKite', "Run the kontrol kite", (options) -> kontrolKite options
task 'proxyKite', "Run the proxy kite", (options) -> proxyKite options
task 'migratePost', "Migrate Posts to JNewStatusUpdate", (options)-> migratePost options
task 'checkConfig', "Check the local config files for errors", (options)-> checkConfig options
task 'runGraphiteFeeder', "Collect analytics from database and feed to grahpite", (options)-> runGraphiteFeeder options
task 'importDB', (options) -> importDB options

# task  = (name, description, action) ->
#   console.log "naber"
#   [action, description] = [description, action] unless action
#   tasks[name] = {name, description, action}


{argv}             = require 'optimist'
{spawn, exec}      = require 'child_process'
log                = { info  : console.log, error : console.log, debug : console.log, warn  : console.log}
processes          = new (require "processes") main : true
{daisy}            = require 'sinkrow'
fs                 = require "fs"
http               = require 'http'
hat                = require 'hat'
url                = require 'url'
nodePath           = require 'path'
portchecker        = require 'portchecker'
Watcher            = require 'koding-watcher'
KONFIG             = require('koding-config-manager').load("main.#{argv.c}")



require 'colors'

addFlags = (options)->
  flags  = ""
  flags += " -a #{options.domain}" if options.domain
  flags += " -d" if options.debug
  flags += " -v" if options.verbose
  return flags

compileGoBinaries = (options, callback = ->)->
  unless KONFIG.compileGo then return callback null

  processes.spawn
    name    : 'build go'
    cmd     : './go/build.sh'
    restart : no
    onExit  :->
      unless options.configFile is 'vagrant' then return callback null
      processes.spawn
        name    : 'build go in vagrant'
        cmd     : "vagrant ssh default --command '/opt/koding/go/build.sh bin-vagrant'"
        restart : no
        onExit  : -> callback null

kloudKite = (options, callback = ->)->

  cmd = """go run #{KONFIG.projectRoot}/go/src/koding/kites/kloud/main.go -c #{options.configFile} -r #{options.configFile} -public-key #{KONFIG.projectRoot}/certs/test_kontrol_rsa_public.pem -private-key #{KONFIG.projectRoot}/certs/test_kontrol_rsa_private.pem -kontrol-url "ws://koding.io:4000"
  """
  processes.run 'kloudKite', cmd

webserver = (options, callback=->)->
  {configFile, tests, region} = options

  {webserver,sourceServer} = KONFIG

  runServer = (config, port, index) ->
    if region is "kodingme"
      cmd = __dirname + "/server/index -c #{configFile} -p #{port}#{if tests then ' -t' else ''} --disable-newrelic"
    else
      cmd = __dirname + "/server/index -c #{configFile} -p #{port}#{if tests then ' -t' else ''}"

    processes.fork
      name              : "server"
      cmd               : cmd
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
      cmd            : __dirname + "/server/lib/source-server -c #{options.configFile} -p #{sourceServer.port}"

  if webserver.watch is yes
    watcher = new Watcher
      groups        :
        server      :
          folders   : ['./server', './workers/social']
          onChange  : ->
            processes.kill "server"

socialWorker = (options, callback=->)->
  {configFile,region} = options

  {social} = KONFIG

  for i in [1..social.numberOfWorkers]
    port = 3029 + i
    kitePort = port + 10000

    if region is "kodingme"
      cmd = __dirname + "/workers/social/index -c #{options.configFile} -p #{port} --disable-newrelic"
    else
      cmd = __dirname + "/workers/social/index -c #{options.configFile} -p #{port}"

    processes.fork
      name           : if social.numberOfWorkers is 1 then "social" else "social-#{i}"
      cmd            : cmd + " --kite-port=#{kitePort}"
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

  if social.watch is yes
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

logWorker = (options, callback)->


  {log} = KONFIG

  for i in [1..log.numberOfWorkers]
    port = 4029 + i

    processes.fork
      name           : if log.numberOfWorkers is 1 then "log" else "log-#{i}"
      cmd            : __dirname + "/workers/log/index -c #{options.configFile} -p #{port}"
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

authWorker = (options, callback=->)->


  config = KONFIG.authWorker
  numberOfWorkers = if config.numberOfWorkers then config.numberOfWorkers else 1

  for i in [1..numberOfWorkers]
    processes.fork
      name  		 : if numberOfWorkers is 1 then "auth" else "auth-#{i}"
      cmd   		 : __dirname+"/workers/auth/index -c #{options.configFile}"
      kontrol        :
        enabled      : !!KONFIG.runKontrol
        startMode    : "many"

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

guestCleanerWorker = (options, callback=->) ->

  processes.fork
    name           : 'guestCleanerWorker'
    cmd            : "./workers/guestcleaner/index -c #{options.configFile}"
    kontrol        :
      enabled      : if KONFIG.runKontrol is yes then yes else no
      startMode    : "one"

  watcher = new Watcher
    groups        :
      guestcleaner:
        folders   : ['./workers/guestcleaner']
        onChange  : (path) ->
          processes.kill "guestCleanerWorker"

emailConfirmationCheckerWorker = (options, callback=->)->

  processes.fork
    name           : 'emailConfirmationCheckerWorker'
    cmd            : "./workers/emailconfirmationchecker/index -c #{options.configFile}"
    kontrol        :
      enabled      : if KONFIG.runKontrol is yes then yes else no
      startMode    : "one"

  watcher = new Watcher
    groups        :
      guestcleaner:
        folders   : ['./workers/emailconfirmationchecker']
        onChange  : (path) ->
          processes.kill "emailConfirmationCheckerWorker"

sitemapGeneratorWorker = (options, callback=->)->

  processes.fork
    name           : 'sitemapGeneratorWorker'
    cmd            : "./workers/sitemapgenerator/index -c #{options.configFile}"
    kontrol        :
      enabled      : if KONFIG.runKontrol is yes then yes else no
      startMode    : "one"

  watcher = new Watcher
    groups        :
      sitemapgenerator:
        folders   : ['./workers/sitemapgenerator']
        onChange  : (path) ->
          processes.kill "sitemapGeneratorWorker"

emailWorker = (options, callback=->)->

  processes.fork
    name           : 'email'
    cmd            : "./workers/emailnotifications/index -c #{options.configFile}"
    kontrol        :
      enabled      : if KONFIG.runKontrol is yes then yes else no
      startMode    : "one"

  watcher = new Watcher
    groups        :
      email       :
        folders   : ['./workers/emailnotifications']
        onChange  : (path) ->
          processes.kill "emailWorker"

emailSender = (options, callback=->)->

  processes.fork
    name           : 'emailSender'
    cmd            : "./workers/emailsender/index -c #{options.configFile}"
    kontrol        :
      enabled      : if KONFIG.runKontrol is yes then yes else no
      startMode    : "one"

  watcher = new Watcher
    groups        :
      email       :
        folders   : ['./workers/emailsender']
        onChange  : (path) ->
          processes.kill "emailSender"

goBroker = (options, callback=->)->
  uuid = hat()
  processes.spawn
    name              : 'broker'
    cmd               : "./go/bin/broker -c #{options.configFile} -u #{uuid} #{addFlags options}"
    kontrol           :
      enabled         : if KONFIG.runKontrol is yes then yes else no
      binary          : uuid
      port            : KONFIG.broker.port
      hostname        : options.domain

premiumBroker = (options, callback=->)->
  uuid = hat()
  processes.spawn
    name              : 'premiumBroker'
    cmd               : "./go/bin/broker -c #{options.configFile} -u #{uuid} -b premiumBroker #{addFlags options}"
    kontrol           :
      enabled         : if KONFIG.runKontrol is yes then yes else no
      binary          : uuid
      port            : KONFIG.broker.port
      hostname        : options.domain

goBrokerKite = (options, callback=->)->
  uuid = hat()
  processes.spawn
    name              : 'brokerKite'
    cmd               : "./go/bin/broker -c #{options.configFile} -u #{uuid} -b brokerKite #{addFlags options}"
    kontrol           :
      enabled         : if KONFIG.runKontrol is yes then yes else no
      binary          : uuid
      port            : KONFIG.broker.port
      hostname        : options.domain

premiumBrokerKite = (options, callback=->)->
  uuid = hat()
  processes.spawn
    name              : 'premiumBrokerKite'
    cmd               : "./go/bin/broker -c #{options.configFile} -u #{uuid} -b premiumBrokerKite #{addFlags options}"
    kontrol           :
      enabled         : if KONFIG.runKontrol is yes then yes else no
      binary          : uuid
      port            : KONFIG.broker.port
      hostname        : options.domain

rerouting = (options, callback=->)->

  processes.spawn
    name           : 'rerouting'
    cmd            : "./go/bin/rerouting -c #{options.configFile}"
    kontrol        :
      enabled      : if KONFIG.runKontrol is yes then yes else no
      startMode    : "one"

userpresence = (options, callback=->)->
  processes.spawn
    name           : 'userPresence'
    cmd            : "./go/bin/userpresence -c #{options.configFile}"
    restart        : yes
    kontrol        :
      enabled      : if KONFIG.runKontrol is yes then yes else no
      startMode    : "one"

elasticsearchfeeder = (options,callback=->)->


  processes.spawn
    name    : "elasticsearchfeeder"
    cmd     : "./go/bin/elasticsearchfeeder -c #{options.configFile} #{addFlags options}"
    restart : yes
    kontrol        :
      enabled      : if KONFIG.runKontrol is yes then yes else no
      startMode    : "one"

kontrolClient = (options,callback=->)->

  processes.run 'kontrolClient', "./go/bin/kontrolclient -c #{options.configFile}"

kontrolProxy = (options, callback=->) ->
  processes.run 'kontrolProxy', "./go/bin/kontrolproxy -c #{options.configFile}"

kontrolDaemon = (options, callback=->)->
  processes.run 'kontrolDaemon', "./go/bin/kontroldaemon -c #{options.configFile} #{addFlags options}"

kontrolApi = (options,callback=->)->
  processes.run 'kontrolApi', "./go/bin/kontrolapi -c #{options.configFile}"

kontrolKite = (options, callback=->)->
  if options.region is "kodingme"
    cmd = "#{KONFIG.projectRoot}/go/bin/kontrol -c #{options.configFile} -r #{options.region}"
  else
    cmd = "vagrant ssh default -c 'cd /opt/koding; sudo killall -q -KILL kontrol; sudo KITE_HOME=/opt/koding/kite_home/koding /opt/koding/go/bin-vagrant/kontrol -c #{options.configFile} -r vagrant'"

  processes.run 'kontrolKite', cmd

proxyKite = (options, callback=->)->
  if options.region is "kodingme"
    cmd = "#{KONFIG.projectRoot}/go/bin/reverseproxy -region #{options.region} -host koding.io -env production"
  else
    cmd = "vagrant ssh default -c 'cd /opt/koding; sudo killall -q -KILL proxy; sudo KITE_HOME=/opt/koding/kite_home/koding /opt/koding/go/bin-vagrant/proxy -c #{options.configFile} -r vagrant'"
  processes.run 'proxyKite', cmd

checkConfig = (options,callback=->)->
  console.log "[KONFIG CHECK] If you don't see any errors, you're fine."
  require('koding-config-manager').load("main.#{options.configFile}")
  require('koding-config-manager').load("kite.applications.#{options.configFile}")
  require('koding-config-manager').load("kite.databases.#{options.configFile}")

runGraphiteFeeder = (options, callback=->)->
  processes.run 'graphiteFeeder',"./go/bin/graphitefeeder -c #{options.configFile}"

migratePost = (options,callback=->)->
  processes.run 'migratePost', "./go/bin/posts -c #{options.configFile}"

run =(options)->

  process.stdout.setMaxListeners 100
  process.stderr.setMaxListeners 100

  invoke 'kontrolDaemon'                    if KONFIG.runKontrol
  invoke 'kontrolApi'                       if KONFIG.runKontrol
  invoke 'kontrolKite'                      if KONFIG.runKontrol
  invoke 'proxyKite'                        if KONFIG.runKloud
  invoke 'kloudKite'                        if KONFIG.runKloud
  invoke 'goBroker'                         if KONFIG.runGoBroker
  invoke 'goBrokerKite'                     if KONFIG.runGoBrokerKite
  invoke 'premiumBroker'                    if KONFIG.runPremiumBroker
  invoke 'premiumBrokerKite'                if KONFIG.runPremiumBrokerKite
  invoke 'rerouting'                        if KONFIG.runRerouting
  invoke 'userpresence'                     if KONFIG.runUserPresence
  invoke 'persistence'                      if KONFIG.runPersistence
  invoke 'elasticsearchfeeder'              if KONFIG.elasticSearch.enabled
  invoke 'authWorker'                       if KONFIG.authWorker
  invoke 'guestCleanerWorker'               if KONFIG.guestCleanerWorker.enabled
  invoke 'emailConfirmationCheckerWorker'   if KONFIG.emailConfirmationCheckerWorker.enabled
  invoke 'emailWorker'                      if KONFIG.emailWorker?.run is yes
  invoke 'emailSender'                      if KONFIG.emailSender?.run is yes
  invoke 'logWorker'                        if KONFIG.log.runWorker

  setTimeout ->
    invoke 'webserver'
    invoke 'socialWorker'
  ,30000

importDB = (options, callback = ->)->
  if options.configFile in ['vagrant', 'kodingme']

    check = """ mongo localhost/koding --quiet --eval="print(db.jGroups.count({slug:'guests'}))" """

    exec check, (err, stdout, stderr)->

      if err or stderr
        console.error "An error occured:", err or stderr
        callback null

      else if stdout is "1\n"
        console.warn "DB already exists, not importing at this time."
        callback null

      else
        command = "tar jxvf ./install/default-db-dump.tar.bz2 && mongorestore -hlocalhost -dkoding dump/koding && rm -rf ./dump"
        exec command, (err, stdout, stderr)->
          console.log stdout
          console.error stderr if stderr
          console.info "DB didn't exists I created a blank one."
          callback null

  else

    callback null


task 'run', (options)->

  options.buildClient = KONFIG.buildClient
  buildEverything options, -> run options


buildEverything = (options, callback = ->)->

  daisy queue = [
    ->
      oldIndex = nodePath.join __dirname, "website/index.html"
      fs.unlinkSync oldIndex  if fs.existsSync oldIndex
      queue.next()
  ,
    ->
      if options.buildClient
        options.callback = -> queue.next()
        buildClient options
      else
        queue.next()
  ,
    -> importDB options, -> queue.next()
  ,
    -> compileGoBinaries options, -> queue.next()
  ,
    -> callback null
  ]


task 'buildEverything', "Build everything and exit.", (options)->

  options.buildClient = yes
  options.watch = no

  buildEverything options


buildClient = (options)->

  buildMethod =
    if options.dontBuildSprites
    then 'buildClient'
    else 'buildSprites'

  (new (require('./Builder')))[buildMethod] options


task 'buildClient', "Build the static web pages for webserver", (options)->
  buildClient options

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
