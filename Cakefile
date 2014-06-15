option '-C', '--buildClient', 'override buildClient flag with yes'
option '-c', '--configFile [CONFIG]', 'What config file to use.'
option '-s', '--dontBuildSprites', 'dont build sprites'
option '-g', '--evengo', 'pass evengo to corresponding command'
option '-r', '--region [REGION]', 'region flag'

require 'colors'

require('coffee-script').register()
{argv}             = require 'optimist'
{exec}              = require 'child_process'
processes          = new (require "processes") main : true
{daisy}            = require 'sinkrow'
nodePath           = require 'path'
Watcher            = require 'koding-watcher'
KONFIG             = require('koding-config-manager').load("main.#{argv.c}")


task 'runOneKite','run a kite',(options) ->
  #TBD 
  "run a singular kite here, like cake -kite social "


checkConfig = (options,callback=->)->
  console.log "[KONFIG CHECK] If you don't see any errors, you're fine."
  require('koding-config-manager').load("main.#{options.configFile}")
  require('koding-config-manager').load("kite.applications.#{options.configFile}")
  require('koding-config-manager').load("kite.databases.#{options.configFile}")
    
    

importDB = (options, callback = ->)->
  return callback null unless options.configFile in ['vagrant', 'kodingme']  
  exec """
  if [[ $(mongo localhost/koding --quiet --eval="print(db.jGroups.count({slug:'guests'}))") -eq 0 ]]; then
    tar jxvf ./install/default-db-dump.tar.bz2 && mongorestore -hlocalhost -dkoding dump/koding && rm -rf ./dump
  """, (err, stdout, stderr)->
        console.log stdout
        console.error stderr if stderr          
        callback null

task 'run', (options)->
  process.stdout.setMaxListeners 100
  process.stderr.setMaxListeners 100

  (val.process.name = key; processes.spawn val.process) for key,val of KONFIG when val?.process?.run


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
    -> callback null
  ]


task 'buildEverything', "Build everything and exit.", (options)->

  options.buildClient = yes
  options.watch = no
  buildEverything options

buildClient = (options)->
  buildMethod = if options.dontBuildSprites then 'buildClient' else 'buildSprites'
  (new (require('./Builder')))[buildMethod] options


task 'buildClient', "Build the static web pages for webserver", (options)-> buildClient options
task 'deleteCache', "Delete the local webserver cache", (options)-> (exec "rm -rf #{__dirname}/.build",-> console.log "Cache is pruned.")

task 'cleanup', "Removes every cache, and file which is not committed yet", (options)->
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






