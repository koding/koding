option '-d', '--database [DB]', 'specify the db to connect to [local|vpn|wan]'
option '-D', '--debug', 'runs with node --debug'
option '-P', '--pistachios', "as a post-processing step, it compiles any pistachios inline"
option '-b', '--runBroker', 'should it run the broker locally?'
option '-C', '--buildClient', 'override buildClient flag with yes'
option '-B', '--configureBroker', 'should it configure the broker?'
option '-c', '--configFile [CONFIG]', 'What config file to use.'

{spawn, exec} = require 'child_process'
# mix koding node modules into node_modules
exec "ln -sf `pwd`/node_modules_koding/* `pwd`/node_modules",(a,b,c)->
  # can't run the program if this fails,
  if a or b or c
    console.log "Couldn't mix node_modules_koding into node_modules, exiting. (failed command: ln -sf `pwd`/node_modules_koding/* `pwd`/node_modules)"
    process.exit(0)


ProgressBar = require './builders/node_modules/progress'
Builder     = require './builders/Builder'
S3          = require './builders/s3'
log4js      = require "./builders/node_modules/log4js"
log         = log4js.getLogger("[Main]")
prompt      = require './builders/node_modules/prompt'
hat         = require "./builders/node_modules/hat"
mkdirp      = require './builders/node_modules/mkdirp'
commander     = require './builders/node_modules/commander'

sourceCodeAnalyzer = new (require "./builders/SourceCodeAnalyzer.coffee")
processes       = new (require "processes") main:true
closureCompile  = require 'koding-closure-compiler'
{daisy}         = require 'sinkrow'
fs            = require "fs"
http          = require 'http'
url           = require 'url'
nodePath      = require 'path'
Watcher       = require "koding-watcher"

KODING_CAKE = './node_modules/koding-cake/bin/cake'


# announcement section, don't delete it. comment out old announcements, make important announcements from here.
console.log "###############################################################"
console.log "#    ANNOUNCEMENT: CODEBASE FOLDER STRUCTURE HAS CHANGED      #"
console.log "# ----------------------------------------------------------- #"
console.log "#    1- node_modules_koding is now where we store our node    #"
console.log "#      modules. ./node_modules dir is completely ignored.     #"
console.log "#      ./node_modules_koding is symlinked/mixed into          #"
console.log "#      node_modules so you can use it as usual. Just don't    #"
console.log "#      make a new one in ./node_modules, it will be ignored.  #"
console.log "# ----------------------------------------------------------- #"
console.log "#    2- `cake install` is now equivalent to `npm install`     #"
console.log "# ----------------------------------------------------------- #"
console.log "#    3- do NOT `npm install [module]` add to package.json     #"
console.log "#      and do another `npm install` or you will mess deploy.  #"
console.log "# ----------------------------------------------------------- #"
console.log "#                       questions and complaints 1-877-DEVRIM #"
console.log "###############################################################"
# log =
#   info  : console.log
#   debug : console.log
#   warn  : console.log


# create required folders
mkdirp.sync "./.build/.cache"



# get current version
# version = (fs.readFileSync ".revision").toString().replace("\r","").replace("\n","")
# if process.argv[2] is 'buildForProduction'
#   rev = ((fs.readFileSync ".revision").toString().replace("\n","")).split(".")
#   rev[2]++
#   version = rev.join(".")
# else
#   version = (fs.readFileSync ".revision").toString().replace("\r","").replace("\n","")

clientFileMiddleware  = (options, code, callback)->
  # console.log 'args', options
  # here you can change the content of kd.js before it's written to it's final file.
  # options is the cakefile options, opt is where file is passed in.
  {libraries,kdjs} = code
  {minify}         = options



  kdjs =  "var KD = {};\n" +
          "KD.config = "+JSON.stringify(options.runtimeOptions)+";\n"+
          kdjs

  if minify
    closureCompile (libraries+kdjs),(err,data)->
      unless err
        callback null,data
      else
        # if error just provide the original file. so site isn't down until this is fixed.
        callback null,(libraries+kdjs)
  else
    callback null,(libraries+kdjs)

normalizeConfigPath =(path)->
  path ?= './config/dev'
  nodePath.join __dirname, path

buildClient =(configFile, callback=->)->
  # try
  #   config = require configFile
  # catch e
  #   console.log 'hello', e
  # builder = new Builder config.client, clientFileMiddleware, ""
  # builder.watcher.initialize()
  # builder.watcher.on 'initDidComplete', ->
  #   builder.buildClient "", ->
  #     builder.buildCss "", ->
  #       builder.buildIndex "", ->
  #         callback null

  configFile = expandConfigFile configFile
  config = require configFile
  console.log config
  builder = new Builder config.client,clientFileMiddleware,""


  builder.watcher.initialize()

  builder.watcher.on "initDidComplete",(changes)->
    builder.buildClient "",()->
      builder.buildCss "",()->
        builder.buildIndex "",()->
          if config.client.watch is yes
            log.info "started watching for changes.."
            builder.watcher.start 1000
          else
            log.info "Done building client"
          callback null

  builder.watcher.on "changeDidHappen",(changes)->
    # log.info changes
    if changes.Client? and not changes.StylusFiles
      builder.buildClient "",()->
        builder.buildIndex "",()->
          # log.debug "client build is complete"

    if changes.Client?.StylusFiles?
      builder.buildCss "", ->
        builder.buildIndex "", ->
    if changes.Cake
      log.debug "Cakefile changed.."
      builder.watcher.reInitialize()

  builder.watcher.on "CoffeeScript Compile Error",(filePath,error)->
    log.error "CoffeeScript ERROR, last good known version of #{filePath} is compiled. Please fix this error and recompile. #{error}"
    spawn.apply null, ["say",["coffee script error"]]

task 'buildClient', (options)->
  configFile = normalizeConfigPath expandConfigFile options.configFile
  buildClient configFile

task 'configureRabbitMq',->
  exec 'which rabbitmq-server',(a,stdout,c)->
    if stdout is ''
      console.log "Please install RabbitMQ. (do e.g. brew install rabbitmq)"
    else
      exec 'rabbitmq-plugins enable rabbitmq_tracing',(a,b,c)->
        console.log a,b,c
        exec 'rabbitmq-plugins enable rabbitmq_management_visualiser',(a,b,c)->
          console.log """
            I will TRY to download and install https://github.com/downloads/tonyg/presence-exchange/rabbit_presence_exchange-20120411.01.ez
            you should find the path where rabbitmq plugins are installed, on mac after brew install;
            /usr/local/Cellar/rabbitmq/2.7.1/lib/rabbitmq/erlang/lib/rabbitmq-2.7.1/plugins
            it is here. look at the output below, it might be somehwere there..
            OK TRYING... if that doesn't work, find the path, ping chris on skype :)
            """
          exec 'rabbitmq-plugins --invalidOption',(a,b,c)->
            d = c.split "\n"
            for line in d
              if line.indexOf("/plugins") > 0
                e = line
                break
            e = e.trim().replace /"|]|,/g,""
            rabbitMqPluginPath = e
            exec "wget -O #{rabbitMqPluginPath}/rabbit_presence_exchange.ez https://github.com/downloads/tonyg/presence-exchange/rabbit_presence_exchange-20120411.01.ez",(a,b,c)->
              exec 'rabbitmq-plugins enable rabbit_presence_exchange',(a,b,c)->
                console.log a,b,c
                exec 'rabbitmqctl stop',->
                  console.log "ALL DONE. (hopefully) - start RabbitMQ server, run: rabbitmq-server (to detach: -detached)"

expandConfigFile = (short="dev")->
  switch short
    when "dev","prod","local","stage","local-go"
      long = "./config/#{short}.coffee"
    else
      short

configureBroker = (options,callback=->)->
  configFilePath = expandConfigFile options.configFile
  configFile = normalizeConfigPath configFilePath
  config = require configFile
  vhosts = "{vhosts,["+
    (options.vhosts or []).
    map(({rule, vhost})-> "{\"#{rule}\",<<\"#{vhost}\">>}").
    join(',')+"]}"

  brokerConfig = """
  {application, broker,
   [
    {description, ""},
    {vsn, "1"},
    {registered, []},
    {applications, [
                    kernel,
                    stdlib,
                    sockjs,
                    cowboy
                   ]},
    {mod, { broker_app, []}},
    {env, [
      {mq_host, "#{config.mq.host}"},
      {mq_user, <<"#{config.mq.login}">>},
      {mq_pass, <<"#{config.mq.password}">>},
      {mq_vhost, <<"#{config.mq.vhost ? '/'}">>},
      {pid_file, <<"#{config.mq.pidFile}">>},
      #{vhosts},
      {verbosity, info},
      {privateRegEx, ".private$"},
      {precondition_failed, <<"Request not allowed">>}
      ]}
   ]}.
  """
  fs.writeFileSync "#{config.projectRoot}/broker/apps/broker/src/broker.app.src",brokerConfig
  callback null

task 'buildforproduction','set correct flags, and get ready to run in production servers.',(options)->
  invoke 'buildForProduction'

task 'buildForProduction','set correct flags, and get ready to run in production servers.',(options)->

  config = require './config/prod.coffee'

  prompt.start()
  prompt.get [{message:"I will build revision:#{version} is this ok? (yes/no)",name:'p'}],  (err, result) ->

    if result.p is "yes"
      log.debug 'version',version
      fs.writeFileSync "./.revision",version
      invoke 'run',options
      console.log "YOU HAVE 10 SECONDS TO DO CTRL-C. CURRENT REV:#{version}"
    else
      process.exit()

task 'configureBroker',(options)->
  configureBroker options

task 'buildBroker', (options)->
  configureBroker options, ->
    pipeStd(spawn './broker/build.sh')

pipeStd =(children...)->
  for child in children when child?
    child.stdout.pipe process.stdout
    child.stderr.pipe process.stderr

run =(options)->

  configFile = normalizeConfigPath expandConfigFile options.configFile
  config = require configFile

  fs.writeFileSync config.monit.webCake, process.pid, 'utf-8' if config.monit?.webCake?

  pipeStd(spawn './broker/start.sh') if options.runBroker

  debug = if options.debug then ' -D' else ''

  if config.runGoBroker
    processes.run
      name  : 'goBroker'
      cmd   : "./go/bin/broker -c #{options.configFile}"
      restart: yes
      restartInterval: 100
      stdout  : process.stdout
      stderr  : process.stderr
      verbose : yes

  processes.run
    name    : 'socialCake'
    cmd     : "#{KODING_CAKE} ./workers/social -c #{configFile} -n #{config.social.numberOfWorkers}#{debug} run"
    restart : yes
    restartInterval : 1000
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes

  processes.run
    name    : 'serverCake'
    cmd     : "#{KODING_CAKE} ./server -c #{configFile}#{debug} run"
    restart : yes
    restartInterval : 1000
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes
  # pipeStd(
  #   processes.get "server"
  #   processes.get "social"
  # )
  if config.social.watch? is yes
    watcher = new Watcher
      groups:
        social :
          folders : ['./workers/social']
          onChange : (path) ->
            processes.kill "socialCake"
        server :
          folders : ['./server']
          onChange : (path)->
            console.log "changed",path
            processes.kill "serverCake"

assureVhost =(uri, vhost, vhostFile, callback)->
  addVhost uri, vhost, (res)->
    if res.type is 'error'
      console.log 'received an error:'.yellow
      console.error res.message
      console.log "it probably doesn't matter; ignoring...".yellow
    fs.writeFileSync vhostFile, vhost, 'utf8'
    callback null

addVhost =(uri, vhost, callback)->
  options = url.parse uri+"?vhost=#{vhost}"
  req = http.request options, (res)->
    responseText = ''
    res.on 'data', (data)-> responseText += data
    res.on 'end', ->
      response =\
        try
          JSON.parse(responseText)
        catch e
          responseText
      callback response
  req.on 'error', console.log
  req.end()

configureVhost =(config, callback)->
  {uri} = config.vhostConfigurator
  vhostFile = nodePath.join(config.projectRoot, '.rabbitvhost')
  try
    vhost = fs.readFileSync vhostFile, 'utf8'
    assureVhost uri, vhost, vhostFile, callback
  catch e
    if e.code is 'ENOENT'
      {explanation} = config.vhostConfigurator
      console.log explanation.bold.red
      commander.prompt 'Please give your vhost a name: ', (name)->
        assureVhost uri, name, vhostFile, callback
    else throw e

task 'run', (options)->
  # invoke 'checkModules'
  configFile = normalizeConfigPath expandConfigFile options.configFile
  config = require configFile

  config.buildClient = yes if options.buildClient

  queue = []
  if config.vhostConfigurator?
    queue.push -> configureVhost config, -> queue.next()
    queue.push ->
      # we need to clear the cache so that other modules will get the
      # config that reflects our latest changes to the .rabbitvhost file:
      configModulePath = require.resolve configFile
      delete require.cache[configModulePath]
      queue.next()

  if options.buildClient ? config.buildClient
    queue.push -> buildClient options.configFile, -> queue.next()
  if options.configureBroker ? config.configureBroker
    queue.push -> configureBroker options, -> queue.next()
  queue.push -> run options
  daisy queue

task 'buildAll',"build chris's modules", ->

  buildables = ["processes","pistachio","scrubber","sinkrow","mongoop","koding-dnode-protocol","jspath","bongo-client"]
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

task 'install', 'install all modules in CakeNodeModules.coffee, get ready for build',(options)->
  # l = (d) -> log.info d.replace /\n+$/, ''
  # {our_modules, npm_modules} = require "./CakeNodeModules"
  # reqs = npm_modules
  # for name,ver of reqs
  processes.run
    name    : "npm install"
    cmd     : "npm install"
    restart : no
    stdout  : process.stdout
    stderr  : process.stderr
    verbose : yes
  # exe = ("npm i "+name+"@"+ver for name,ver of reqs).join ";\n"
  # a = exec exe,->
  # a.stdout.on 'data', l
  # a.stderr.on 'data', l

task 'uninstall', 'uninstall all modules listed in CakeNodeModules.coffee',(options)->
  l = (d) -> log.info d.replace /\n+$/, ''
  {our_modules, npm_modules} = require "./CakeNodeModules"
  reqs = npm_modules
  exe = "npm uninstall "+(name for name,ver of reqs).join " "
  a = exec exe,->
  a.stdout.on 'data', l
  a.stderr.on 'data', l

task 'checkModules', 'check node_modules dir',(options)->
  {our_modules, npm_modules} = require "./CakeNodeModules"
  required_versions = npm_modules
  npm_modules = (name for name,ver of npm_modules)
  gitIgnore = ((fs.readFileSync "./.gitignore").toString().replace(/\r\n/g,"\n").split "\n")

  data = fs.readdirSync "./node_modules"
  untracked_mods = (mod for mod in data when mod not in our_modules and mod not in npm_modules and "/node_modules/#{mod}" not in gitIgnore)
  if untracked_mods.length > 0
    for umod,i in untracked_mods
      console.log umod,i
      try
        untracked_mods[i] = umod+"@"+(JSON.parse(fs.readFileSync "./node_modules/#{umod}/package.json")).version
      catch e
        console.log umod
    console.log "[ERROR] UNTRACKED MODULES FOUND:",untracked_mods
    console.log "Untracked modules detected add each either to CakeNodeModules.coffee, and/or to .gitignore (exactly as: e.g. /node_modules/#{untracked_mods[0]}). Exiting."
    process.exit()

  unignored_mods = (mod for mod in data when mod not in our_modules and "/node_modules/#{mod}" not in gitIgnore)
  if unignored_mods.length > 0
    console.log "[ERROR] UN-IGNORED NPM MODULES FOUND:",unignored_mods
    console.log "Don't do git-add before adding them to .gitignore (exactly as: e.g. /node_modules/#{unignored_mods[0]}). Exiting."
    process.exit()

  # check if versions match
  for mod,ver of required_versions when (packageVersion = (JSON.parse(fs.readFileSync "./node_modules/#{mod}/package.json")).version) isnt required_versions[mod]
    log.error "[ERROR] NPM MODULE VERSION MISMATCH: #{mod} version is incorrect:#{packageVersion}. it has to be #{ver}."
    log.info  "If you want to keep this version edit CakeNodeModules.coffee or run: npm install #{mod}@#{ver}"
    process.exit()

  all_mods = npm_modules.concat our_modules
  uninstalled_mods = (mod for mod in all_mods when mod not in data)
  if uninstalled_mods.length > 0
    console.log "[ERROR] UNINSTALLED MODULES FOUND:",uninstalled_mods
    console.log "Please run: npm install #{uninstalled_mods.join(" ")} (or cake install)"
    console.log "Exiting."
    process.exit()
  else
    console.log "./node_modules check complete."



task 'writeGitIgnore','updates a part of .gitignore file to avoid conflicts in ./node_modules',(options)->

  fs.readFile "./.gitignore",'utf8',(err,data)->
    arr = data.split "\n"

task 'build', 'optimized version for deployment', (options)->
  # invoke 'checkModules'
  # # require './server/dependencies.coffee' # check if you have all npm libs to run kfmjs
  # options.port      or= 3000
  # options.host      or= "localhost"
  # options.watch     or= 1000
  # options.database  ?= "mongohq-dev"
  # options.port      ?= "3000"
  # options.dontStart ?= no
  # options.uglify    ?= no


  # options.target = targetPaths.server ? "/tmp/kd-server.js"

  # {dontStart,uglify,database} = options
  # build options





























# ------------ OTHER LESS IMPORTANT STUFF ---------------------#

task 'deploy','',(options)->

  fs.readFile "./.revision","utf8",(err,data)->
    throw err if err
    rev = data.replace "\n",""
    filename = "kfmjs-#{rev}.tar.gz"
    execStr = "cd .. && /usr/bin/tar -czf #{filename} --exclude 'kites/*' --exclude '.git/*' kfmjs"
    log.info "executing #{execStr}"
    exec execStr,(err,stdout,stderr)->
      s3 = new S3
        key     : "AKIAJO74E23N33AFRGAQ"
        secret  : "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"
        bucket  : "koding-updater"
      log.info "starting to upload to s3"
      s3.putFile "../#{filename}",filename,(err,res)->
        console.log err,res
        foo = exec "./build/install_sl_vm/install.py --hourly --cores 1 --ram 1 --port 10 --bandwidth 1000 --fqdn web1.prod.system.koding.com",(err,stdout,stderr)->
          # console.log arguments
          depStr = "./build/install_ec2/install_ec2.py --fqdn web#{Date.now()}.beta.system.aws.koding.com --int --kfmjs #{rev} "
          log.info "deploying #{depStr}"
          foo = exec depStr,(err,stdout,stderr)->
            console.log "deployment complete."
        foo.stdout.on 'data', (data)-> log.info "#{data}".replace /\n+$/, ''
        foo.stderr.on 'data', (data)-> log.info "#{data}".replace /\n+$/, ''

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
