fs                = require 'fs'
path              = require 'path'
sys               = require 'util'
{spawn, exec}     = require 'child_process'
sqwish            = require './node_modules/sqwish'
stylus            = require 'stylus'
# {parser, uglify}  = require "uglify-js"
cs                = require './node_modules/coffee-script'
Watcher           = require './Watcher'
ProcessMonitor    = require './ProcessMonitor'
log =
  info  : console.log
  error : console.log
  debug : console.log
  warn  : console.log
  
ProgressBar       = require './node_modules/progress'

module.exports = class Builder

  constructor:(builderOptions,@middleware,fileList="deprecated")->
    # exec """grep "^class " client/Framework/* -R | awk '{split($0,a,":"); split(a[2], b, " "); print "KD.classes[\\""b[2]"\\"]="b[2];}' | uniq > ./client/Framework/classregistry.coffee"""
    exec """grep "^class " client/Framework/* -R | awk '{split($0,a,":"); split(a[2], b, " "); print "KD.classes."b[2]"="b[2];}' | uniq > ./client/Framework/classregistry.coffee"""

    @options              = builderOptions.config
    @commandLineOptions   = builderOptions.commandLine

    @watcher = new Watcher @options.includesFile

    @attachListeners()

  attachListeners:()->

      # rebuild changes,options

  build:(options)->

  # uglify:(options,callback)->
  #   ast         = parser.parse(options.js)
  #   ast         = uglify.ast_mangle(ast,{no_functions : options.noMangleFunctions}) if options.mangle
  #   ast         = uglify.ast_squeeze(ast) if options.squeeze
  #   final_code  = uglify.gen_code ast,beautify:options.beautify
  #   return final_code

  resetWatcher:()->
    @watcher = new Watcher @options.includesFile

  # buildApplications:(installedAppsPath, builtJsPath)->
  #   buildPath = fs.realpathSync builtJsPath
  #
  #   installedApps = require installedAppsPath
  #   for appName, appPath of installedApps
  #     do (buildPath, appName, appPath)->
  #       path.exists "#{buildPath}/#{appName}", (exists)->
  #         unless exists
  #           fs.mkdirSync "#{buildPath}/#{appName}", 511
  #         exec "cd #{appPath} && cake -p #{buildPath}/#{appName} build", (err)->
  #           log.info "Application #{appName} built, with result", arguments

  buildClient:(options,callback)->

    moduleDeclaration = @watcher.createModuleDeclarations "Client","Framework"

    clibraries  = @watcher.getSubSectionConcatenated "Client","Libraries"

    cclient = ''
    cclient += if options.pistachios then 'PISTACHIO_MODE = "production";' else ''

    cclient += @watcher.getSubSectionConcatenated "Client","Framework"
    cclient += @watcher.getSubSectionConcatenated "Client","Application"
    cclient += @watcher.getSubSectionConcatenated "Client","Applications"
    cclient += @watcher.getSubSectionConcatenated "Client","ApplicationPageViews"
    cclient = kdjs = @wrapWithJSClosure cclient

    libraries  = clibraries

    @middleware @options, @commandLineOptions, {libraries, kdjs}, (err,finalCode)=>
      fs.writeFile @options.js, finalCode, (err) =>
        log.info "Client code is re-compiled and saved."
        callback? null

  # buildServer:(options,callback)->
  #   cserver  = @watcher.getSubSectionConcatenated "Server","Stuff"
  #   cserver += @watcher.getSubSectionConcatenated "Server","Models"
  #   cserver += @watcher.getSubSectionConcatenated "Server","OtherStuff"
  #   cserver  = @wrapWithJSClosure cserver
  #   fs.writeFile @targetPaths.server,cserver,(err) ->
  #     log.info "Server code is re-compiled."
  #     callback? null

  #   if @options.dontStart
  #     fs.writeFile @targetPaths.serverProd,cserver,(err)=>
  #       unless err
  #         log.info "Server code is copied to #{@targetPaths.serverProd}"
  #       else
  #         log.error "couldn't copy kd-server.js to #{@targetPaths.serverProd}, monit will not work."

  buildCss:(options,callback)->
    cstylus = @watcher.getSubSectionConcatenated "Client","StylusFiles"
    ccssx   = @watcher.getSubSectionConcatenated "Client","CssFiles"
    ccss    = "#{ccssx}\n /* - */ \n#{cstylus}"
    # stylus.render cstylus,(err,css)->
    #   ccss     = @watcher.getSubSectionConcatenated "Client",CssFiles
    #   ccss    += "\n /* next file in line */ \n"+css
    #   ccss     = sqwish.minify ccss if options.uglify
    fs.writeFile @options.css, ccss, (err) ->
      unless err
        log.info "Css files are recompiled and saved."
        callback? null
      else
        log.error "Couldn't build css.."
        callback? yes

  wrapWithJSClosure : (js)-> "(function(){#{js}}).call(this);"

  buildIndex : (options,callback)->
    fs.readFile @options.indexMaster, 'utf-8',(err,data)=>

      index = data
      index = index.replace "js/kd.js","js/kd.#{@options.version}.js?"+Date.now()
      index = index.replace "css/kd.css","css/kd.#{@options.version}.css?"+Date.now()
      if @options.useStaticFileServer is no
        st = "https://api.koding.com"  # CHANGE THIS TO SOMETHING THAT MAKES SENSE tbd
        index = index.replace ///#{st}///g,""
        # log.warn "Static files will be served from NodeJS process. (because -d vpn is used - ONLY DEVS should do this.)"
      fs.writeFile @options.index,index,(err) ->
        throw err if err
        unless err
          log.info "Index.html is ready."
          if require("os").platform() is 'linux'
            exec "notify-send \"Koding instance updated\""
          callback? null
