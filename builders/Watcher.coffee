{EventEmitter}  = require 'events'
cs              = require './node_modules/coffee-script'
stylus          = require './node_modules/stylus'
nib             = require './node_modules/nib'
fs              = require 'fs'
log =
  info  : console.log
  error : console.log
  debug : console.log
  warn  : console.log
unrequire       = (module) -> delete require.cache[require.resolve module]
nodePath        = require "path"
{spawn, exec}   = require 'child_process'
ProgressBar     = require './node_modules/progress'
#{parser, uglify}  = require "uglify-js"
hat             = require "./node_modules/hat"
# {postProcess}   = require "pistachio-compiler"
# qfunction      = require 'qfunction'

class Watcher extends EventEmitter
  constructor:(filelistPath)->
    @watchlist  = {}
    @watcher    =
      isLooping       : no
      isInitializing  : yes
      filelistPath    : filelistPath
      cache           : "/tmp/watcherCache.txt"

    @setWatchList()

  setWatchList:(filelistPath)->
    @watchlist = require @watcher.filelistPath

  resetWatchList:()->
    unrequire @watcher.filelistPath
    @setWatchList()

  start:(interval)->
    if interval?
      log.info "Starting the watcher to check files every #{interval/1000} secs."
      setInterval ()=>
        @watch() unless @watcher.isLooping
      ,interval
    else
      log.info "Starting the watcher once."
      @watch() unless @watcher.isLooping

  reInitialize:(options,callback)->
    log.info "Re-initializing..."
    @resetWatchList()
    @removeCacheFile ()=>
      @initialize options,callback

  removeCacheFile:(callback)->
    fs.unlink @watcher.cache,(err)->
      callback? err


  initialize:(options,callback)->
    @watcher.isInitializing = yes

    @beginFileNameCheck =>
      log.info "Case Sensitive filename check complete."
      unless @watcher.isLooping

        @watch null,()->
          callback? null

  getFileList : (section,subSection)->
    @watchlist

  getSubSectionConcatenated: (section,subSection,code="")->
    if Array.isArray(subSection)
      for sS in subSection
        for key,path of @watchlist.order[section][sS]
          # log.debug path
          if path then code += @watchlist.order.__watch[path].contentsCs+"\n"
      code = cs.compile code,bare:no
      return code
    else
      for key,path of @watchlist.order[section][subSection] when path then code += @watchlist.order.__watch[path].contents+"\n"
      return code

  createModuleDeclarations:(section,subSection)->
    declaration = ""
    for key, path of @watchlist.order[section][subSection]
      declaration += "#{key} : #{key},"
    declaration

  beginFileNameCheck:(callback)->
    caseSensitivityChecker = {}
    paths = []
    for section of @watchlist.order
      if section isnt "__watch"
        for subSection, pkg of @watchlist.order[section]
          for key,path of pkg
            if paths
              paths.push path
            else
              log.warn "wtf situation with paths, check."

    exec "find . -iname '*'",(err,stdout,stderr)->
      paths2 = stdout.split("\n")
      # log.debug paths
      for path1 in paths
        for path2 in paths2
          # log.info "checking #{path2} -> #{path1}"
          if (path1.toLowerCase() is path2.toLowerCase()) and (path1 isnt path2)
            log.error "#{path2} must be #{path1}"
            err1 = yes

      throw new Error "Fix case sensitivity issues before continuing." if err1
      callback null


  watch : (options,callback)->
    @watcher.isLooping = yes
    @watchlist.order.__watch ?= {}
    build =
      server : false
      client : false
      css    : false
      endOfLoop : false
      totalCount : false
    changes = {}
    for section of @watchlist.order
      if section isnt "__watch"
        for subSection, pkg of @watchlist.order[section]
          for key,path of pkg
            build.totalCount++
    bar = new ProgressBar 'Init\'ing includes [:bar] :percent :elapseds',{total: build.totalCount,width:50,incomplete:" "} if @watcher.isInitializing
    for section of @watchlist.order
      if section isnt "__watch"
        for subSection, pkg of @watchlist.order[section]
          for key,path of pkg
            do (section,subSection,pkg,key,path) =>
              @watchlist.order.__watch[path] ?= {}
              file = @watchlist.order.__watch[path]
              fs.stat path,(err,stat)=>
                unless stat?
                  throw new Error "File not found! #{path}"
                mtime = Date.parse(stat.mtime)
                cacheP = cacheFilePath(path)
                fs.stat cacheP,(err,stat)=>
                  cacheMtime = unless err then Date.parse(stat.mtime) else 0
                  file.path        = path
                  file.mtime       = mtime
                  file.lastCompile ?= 0
                  file.contents    ?= ""
                  file.section     = section
                  file.subSection  = subSection
                  file.cacheMtime  = cacheMtime
                  file.cachePath   = cacheP
                  # file["cache"] = "./.build/.cache/"+mtime+path.replace(/\//g,"_")+".txt" # .txt for easy error checking using mac finder.

                  @getFile file, options, (passedFile,newFile)=>
                    bar.tick() if @watcher.isInitializing
                    build.totalCount--
                    if newFile?
                      changes[section] or= {}
                      changes[section][subSection] or= []
                      changes[section][subSection].push path:newFile.path
                      @watchlist.order.__watch[passedFile.path] = newFile

                    if build.totalCount is 0
                      @watcher.isLooping = no
                      if @watcher.isInitializing
                        @emit "initDidComplete",changes
                        log.info "Init complete..."
                        callback? null
                        @watcher.isInitializing = no
                      else
                        for own change of changes
                          @emit "changeDidHappen",changes
                          callback? null
                          break

  getFile:(file, options, callback)->
    if (file.mtime - file.lastCompile) > 0
      # DEBUG # console.log file.cacheMtime,file.mtime,file.lastCompile, file.cacheMtime - file.mtime
      if not file.cacheMtime or (file.cacheMtime - file.mtime) < 0
        @compileFile file, options, (newFile)->
          newFile.lastCompile = Date.now()
          # @writeCache newFile,(err)->
          callback file, newFile
      else
        # console.log "reading"+file.path
        fs.readFile file.cachePath,'utf8',(err,data)->
          # console.log 'serving from cache',file.cachePath
          file.lastCompile = Date.now()
          file.contents = data
          callback file, null
    else
      callback file,null


  compilePistachios = require 'pistachio-compiler'
  cacheFilePath = (path) ->
     p = require('path').normalize(__dirname+"/../.build/.cache/"+path.replace(/\//g,"_"))
  writeCacheFile = (path,content)->
    fs.writeFile cacheFilePath(path),content,'utf8',(err,res)->
      if err
        console.log err
  compileFile: (file, options, callback)->
    ext = file.path.split(".").pop()
    newContent = fs.readFileSync file.path, 'utf-8' #,(err,newContent)=>
    # if err
    #   console.log err
    #   throw new Error "Couldn't open #{file.path}"
    #   process.exit()
    # else
    switch ext
      when "styl"
        stylus(newContent).set('compress',true).use(nib()).render (err,css)=>
          unless err
            file.contents = css
            writeCacheFile file.path,css
            callback file
          else
            lines = err.message.split('\n') or ['0','No details supplied.']
            log.error "\nStylus Compile Error in #{file.path} on line #{lines[0].match(/\d*$/)[0]}"
            log.info line for line in lines[1...]

      when "coffee"
        try
          file.contentsCs = newContent
          # if file.section is "Client"
          #   file.contents = postProcess source:(cs.compile newContent,bare:yes)
          #   # log.debug file.contents
          # else
          file.contents = cs.compile newContent,bare:yes
          writeCacheFile file.path,file.contents

          #file.contents = @uglify js:file.contents,mangle:no,noMangleFunctions:yes,squeeze:no #,beautify:beautify
        catch error
          errd = yes
          log.error "#{(error.stack.split "\n")[0]} at: #{file.path}"
          @emit "CoffeeScript Compile Error",file.path,(error.stack.split "\n")[0]


        callback file
        @emit "coffeeFileContents",file # for sourceCodeAnalyzer.
      else
        file.contents = newContent
        callback file

module.exports  = Watcher


























