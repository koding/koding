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

require 'colors'

addFlags = (options)->
  flags  = ""
  flags += " -a #{options.domain}" if options.domain
  flags += " -d" if options.debug
  flags += " -v" if options.verbose
  return flags

require('coffee-script').register()
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


task 'guestCleanerWorker',  "Run the guest cleanup worker", (options)->   guestCleanerWorker options
task 'socialWorker',        "Run the socialWorker", (options) ->          socialWorker options
task 'kloudKite',           "run kloud kite", (options) ->                kloudKite options
task 'compileGo',           "Compile the local go binaries", (options)->  compileGoBinaries options
task 'webserver',           "Run the webserver", (options) ->             webserver options
task 'logWorker',           "Run the logWorker", (options) ->             logWorker options
task 'authWorker',          "Run the authWorker", (options) ->            authWorker options
task 'goBroker',            "Run the goBroker", (options)->               goBroker options
task 'emailWorker',         "Run the email worker", (options)->           emailWorker options
task 'emailSender',         "Run the emailSender", (options)->            emailSender options
task 'rerouting',           "Run rerouting", (options)->                  rerouting options
task 'userpresence',        "Run userpresence", (options)->               userpresence options
task 'elasticsearchfeeder', "Run the Elastic Search Feeder", (options)->  elasticsearchfeeder options
task 'kontrolClient',       "Run the kontrolClient", (options) ->         kontrolClient options
task 'kontrolProxy',        "Run the kontrolProxy", (options) ->          kontrolProxy options
task 'kontrolDaemon',       "Run the kontrolDaemon", (options) ->         kontrolDaemon options
task 'kontrolApi',          "Run the kontrolApi", (options) ->            kontrolApi options
task 'kontrolKite',         "Run the kontrol kite", (options) ->          kontrolKite options
task 'proxyKite',           "Run the proxy kite", (options) ->            proxyKite options
task 'cronJobs',            "Run CronJobs", (options)->                   cronjobs options
task 'importDB',            "Import blank DB", (options) ->               importDB options
task 'sitemapGeneratorWorker',"Generate the sitemap worker", (options)->  sitemapGeneratorWorker options
task 'migratePosts',        "Migrate Posts to JNewStatusUpdate", (options)-> migratePosts options
task 'checkConfig',         "Check the local config files for errors", (options)-> checkConfig options
task 'graphiteFeeder',      "Collect analytics from database and feed to graphite", (options)-> graphiteFeeder options
task 'emailConfirmationCheckerWorker', "", (options)->                    emailConfirmationCheckerWorker options



webserver       = (options, callback=->) -> processes.spawn KONFIG.webserver.process
socialWorker    = (options, callback=->)-> processes.spawn KONFIG.social.process
logWorker       = (options, callback=->)-> processes.spawn KONFIG.log.process
webserver       = (options, callback=->) -> processes.spawn KONFIG.webserver.process
socialWorker    = (options, callback=->)-> processes.spawn KONFIG.social.process
logWorker       = (options, callback=->)-> processes.spawn KONFIG.log.process
authWorker      = (options, callback=->)-> processes.spawn KONFIG.authWorker.process
guestCleanerWorker = (options, callback=->) ->  processes.spawn KONFIG.guestCleanerWorker.process
emailConfirmationCheckerWorker = (options, callback=->)-> processes.spawn KONFIG.emailConfirmationCheckerWorker.process
sitemapGeneratorWorker = (options, callback=->)-> processes.spawn KONFIG.sitemapGeneratorWorker.process
emailWorker     = (options, callback=->)-> processes.spawn KONFIG.emailWorker.process
emailSender     = (options, callback=->)-> processes.spawn KONFIG.emailSender.process
goBroker        = (options, callback=->)-> processes.spawn KONFIG.broker.process
kloudKite       = (options, callback = ->)-> processes.spawn KONFIG.kloudKite.process
elasticsearchfeeder = (options,callback=->)-> processes.spawn KONFIG.elasticsearchfeeder.process
compileGoBinaries = (options, callback = ->)-> processes.spawn KONFIG.compileGoBinaries.process
rerouting       = (options, callback=->)-> processes.spawn KONFIG.rerouting.process
userpresence    = (options, callback=->)-> processes.spawn KONFIG.userpresence.process
kontrolClient   = (options,callback=->)-> processes.spawn KONFIG.kontrolClient.process
kontrolProxy    = (options, callback=->) -> processes.spawn KONFIG.kontrolProxy.process
kontrolDaemon   = (options, callback=->)-> processes.spawn KONFIG.kontrolDaemon.process
kontrolApi      = (options,callback=->)-> processes.spawn KONFIG.kontrolDaemon.process
kontrolKite     = (options, callback=->)-> processes.spawn KONFIG.kontrolKite.process    
proxyKite       = (options, callback=->)-> processes.spawn KONFIG.proxyKite.process    
cronJobs        = (options, callback=->)-> processes.spawn KONFIG.cronJobs.process
graphiteFeeder  = (options, callback=->)-> processes.spawn KONFIG.graphiteFeeder.process
migratePosts    = (options, callback=->)-> processes.spawn KONFIG.migratePosts.process


checkConfig = (options,callback=->)->
  console.log "[KONFIG CHECK] If you don't see any errors, you're fine."
  require('koding-config-manager').load("main.#{options.configFile}")
  require('koding-config-manager').load("kite.applications.#{options.configFile}")
  require('koding-config-manager').load("kite.databases.#{options.configFile}")
    
    
pressAnyKeyToContinue = ->
  if typeof v8debug is "object"
    readline = require("readline")
    rl = readline.createInterface
      input: process.stdin
      output: process.stdout
    
    rl.question "Press any key to continue...", (answer) ->
      rl.close()
      return
   
    
run =(options)->

  process.stdout.setMaxListeners 100
  process.stderr.setMaxListeners 100
  console.log "im in run."
  i = 0
  for key,val of KONFIG # when KONFIG[key].process?.run
    if val?.process?.run
      i++
      console.log "now running ->", i,key #, val?.process?.run # if key.process?.run is yes
      val.process.name = key
      processes.spawn val.process

      console.log('Press any key to exit');
      process.stdin.setRawMode(true);
      process.stdin.resume();





  # invoke 'kontrolDaemon'                    if KONFIG.runKontrol
  # invoke 'kontrolApi'                       if KONFIG.runKontrol
  # invoke 'kontrolKite'                      if KONFIG.runKontrol
  # invoke 'proxyKite'                        if KONFIG.runKontrol
  # invoke 'kloudKite'                        if KONFIG.runKloud
  # invoke 'rerouting'                        if KONFIG.runRerouting
  # invoke 'persistence'                      if KONFIG.runPersistence
  # invoke 'elasticsearchfeeder'              if KONFIG.elasticSearch.enabled
  # invoke 'authWorker'                       if KONFIG.authWorker
  # invoke 'guestCleanerWorker'               if KONFIG.guestCleanerWorker.enabled
  # invoke 'emailConfirmationCheckerWorker'   if KONFIG.emailConfirmationCheckerWorker.enabled
  # invoke 'emailWorker'                      if KONFIG.emailWorker?.run is yes
  # invoke 'emailSender'                      if KONFIG.emailSender?.run is yes
  # invoke 'cronJobs'
  # invoke 'logWorker'                        if KONFIG.log.runWorker
  # invoke 'webserver'
  # invoke 'socialWorker'

  # invoke 'addTagCategories'
  # invoke 'userpresence'                     if KONFIG.runUserPresence

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
  run options
  # buildEverything options, -> run options


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

task 'addTagCategories','Add new field category to JTag, and set default to "user-tag"',(options)->
  command = """
  mongo localhost/koding --quiet  --eval='db.jTags.update(
    {"category":{$ne:"system-tag"}},{$set:{"category":"user-tag"}},{"multi":"true"})'
  """
  exec command

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
