{spawn, exec}     = require 'child_process'
CoffeeScript      = require 'coffee-script'
fs                = require 'fs'
nib               = require 'nib'
path              = require 'path'
compilePistachios = require 'pistachio-compiler'
ProgressBar       = require 'progress'
SourceMap         = require 'source-map'
base64VLQ         = require 'source-map/lib/source-map/base64-vlq'
Stylus            = require 'stylus'
sprite            = require 'koding-sprites'
UglifyJS          = require 'uglify-js'
WebSocket         = require 'ws'
WebSocketServer   = WebSocket.Server
Promise           = require 'bluebird'
which             = Promise.promisify require 'which'
buildAPI          = require 'bongo-api-builder'

log =
  info  : console.log
  error : console.log
  debug : console.log
  warn  : console.log

formatByte = (bytes) ->
  minus = ''
  if bytes < 0
    minus  = '-'
    bytes *= -1
  thresh    = 1024
  units     = ["kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
  unitIndex = -1
  return "#{bytes} B"  if bytes < thresh
  loop
    bytes /= thresh
    ++unitIndex
    break unless bytes >= thresh

  return "#{minus}#{bytes.toFixed 2} #{units[unitIndex]}"

checkFileCase = (fileName) ->
  basename = path.basename fileName
  dirname  = path.normalize path.dirname fileName
  listing  = fs.readdirSync dirname

  if basename in listing
    if (dirname.split '/').length > 1
    then checkFileCase dirname
    else yes
  else no

module.exports = class Builder

  spriteHelper = null

  canBuildSprites: ->
    hasCanvas = !!try require 'canvas'
    (if hasCanvas then Promise.resolve() else which 'gm').catch (err) ->
      if /^not found:/.test err.message
        console.error "Unmet dependency!  You must install either graphicsmagick or cairo + node-canvas"
        console.error "You can install graphicsmagick using homebrew:"
        console.error "$ brew install graphicsmagick"
        process.exit(1)
      throw err

  buildSprites: (options) ->

    @config ?= require('koding-config-manager').load("main.#{options.configFile}")

    @canBuildSprites().then ->
      log.info "Building sprites... (it may take a while)"
      sprite
        srcPath   : './sprites'
        destPath  : './website/a/sprites'
        httpPath  : '/a/sprites'
    .then (helper) =>
      spriteHelper = helper
      @buildClient options

  buildFramework:->

    @config ?= require('koding-config-manager').load("main.#{options.configFile}")
    cmd = "cd client/Framework && npm i && gulp compile --uglify --outputDir=../../website/a/"
    exec cmd, (err, stdout, stderr)->
      console.log """\n\n
      ################################### FRAMEWORK COMPILED #################################


       To use watcher for Framework use following command in different tab:
       $ #{cmd.replace 'compile ', ''}


      ################################### FRAMEWORK COMPILED #################################
      \n
      """

  buildClient: (options) ->

    @config ?= require('koding-config-manager').load("main.#{options.configFile}")

    if options.watch? then @config.client.watch = options.watch

    try fs.mkdirSync ".build"

    @buildFramework()

    buildAPI
      rootDir   : __dirname
      modelsDir : './workers/social/lib/social/models'
      identifier: "REMOTE_API"
      out       : '.build/api.js'
    , =>
      buildAPI
        rootDir   : __dirname
        modelsDir : './workers/log/lib/log/models'
        identifier: "REMOTE_LOGGING_API"
        out       : '.build/logging-api.js'
      , =>
        @buildAndWatchClient options

  buildAndWatchClient: (options) ->

    @projectsToBuild = {}
    @fileSizes = {}
    @blackList = []

    addProject = (title, project, ptype)=>

      @projectsToBuild[title] =
        title       : title
        includes    : "#{project.path}/includes.coffee"
        routes      : "#{project.path}/routes.coffee"
        subprojects : project.projects
        changed     : no
        fileTimes   : {}
        files       :
          scripts   : []
          styles    : []
        outputs     :
          script    : project.script
          style     : project.style
        type        : ptype
        sourceMapRoot : project.sourceMapRoot ? ''

    {projects, bundles} = require './projects'

    for own title, project of projects
      addProject title, project, 'project'

    for own title, bundle of bundles
      addProject title, bundle, 'bundle'



    # registering app names to KD.config
    # so that we know all the available apps
    # before even loading their sources
    fs.writeFileSync "#{__dirname}/client/Main/__generatedapps__.coffee" , "KD.config.apps=#{@getProjects()}", "utf8"

    # this registers routes just before application runs
    # this is not the best place to put this
    # assuming to refactor this at some point
    # by switching to a task manager - SY
    fs.writeFileSync "#{__dirname}/client/Main/__generatedroutes__.coffee" , @getRoutes(), "utf8"

    @compileChanged options, true

  shortenText:(a, l)->
    l ?= process.stdout.columns - 40
    return a if a.length < l - 5
    return a[0..l/2 - 5] + '...' + a[a.length - l/2..a.length]

  compileChanged: (options, initial) ->

    includesChanged = @readIncludesFile()

    if initial
      total = 0
      for own _key, project of @projectsToBuild when project.type isnt 'bundle'
        total+= project.files.scripts.length + project.files.styles.length

    changedJS  = []
    changedCSS = []

    for own _key, project of @projectsToBuild when project.type isnt 'bundle'

      if initial
        log.info "- Compiling #{project.title} ... "
        bar = new ProgressBar "[:bar] :percent :elapseds", \
          {total : project.files.scripts.length + project.files.styles.length, \
           width : 20, incomplete:" "}

      scriptsChanged = false
      stylesChanged  = false
      folderIndex = 0
      folders = [project.files.scripts, project.files.styles]
      for folder in folders
        for file in folder
          if folderIndex is 0
          then scriptsChanged |= @compileFile file
          else stylesChanged  |= @compileFile file
          continue unless initial
          sp = @shortenText file.sourcePath
          bar.fmt = " [:bar] :percent :elapseds #{sp} "# - #{file.sourcePath}"
          bar.tick()
        folderIndex++

      log.info "" if initial

      if initial or project.changed or scriptsChanged
        @buildJS options, project
        changedJS.push project.title

      if project.outputs.style
        if initial or project.changed or stylesChanged
          @buildCSS options, project
          changedCSS.push project.title

      log.info "" if initial

    log.info "- Compiling bundles ..." if initial
    builtBundles = {js:[], css:[]}
    for own _key, project of @projectsToBuild when project.type is 'bundle'
      for subproject in project.subprojects
        if subproject in changedJS and project not in builtBundles.js
          @buildJS options, project
          builtBundles.js.push project
        if subproject in changedCSS and project not in builtBundles.css
          @buildCSS options, project
          builtBundles.css.push project

    if initial and options.callback?
      options.callback()
      delete options.callback

    if @config.client.watch is yes
      if initial
        log.info "\n All done. Watching for changes... \n"

      setTimeout =>
        @compileChanged options, false
      , @config.client.watchDuration or 5000

  readIncludesFile: ->

    changed = no

    for own _key, project of @projectsToBuild

      if project.type is 'bundle'
        _changed = no

        project.files = scripts:[], styles:[]
        for subproject in project.subprojects
          subproject = @projectsToBuild[subproject]
          project.files.scripts = \
            project.files.scripts.concat subproject.files.scripts
          project.files.styles  = \
            project.files.styles.concat subproject.files.styles
          _changed |= subproject.changed

        project.changed = _changed

      else

        time = Date.parse(fs.statSync(project.includes).mtime)
        if project.fileTime == time
          project.changed = no
          continue

        project.fileTime = time
        project.changed  = yes
        project.files    = scripts:[], styles:[]
        changed |= project.changed
        for includePath in CoffeeScript.eval(fs.readFileSync(project.includes, "utf-8"))

          cachePath = ".build/#{project.title}_#{includePath.replace /\//g, "_" }"

          file =
            sourceMapPath : cachePath + ".map"
            sourceMapRoot : project.sourceMapRoot
            includePath   : includePath
            sourcePath    : "#{path.dirname(project.includes)}/#{includePath}"
            cachePath     : cachePath
            cacheTime     : if fs.existsSync(cachePath) then Date.parse(fs.statSync(cachePath).mtime) else 0
            extension     : path.extname(includePath)

          if file.sourcePath in @blackList
            @blackList.splice (@blackList.indexOf file.sourcePath), 1
          else if not checkFileCase file.sourcePath
            log.error "File is missing or misspelled: #{ file.sourcePath }"
            process.exit 1

          switch file.extension
            when ".coffee", ".js"
              project.files.scripts.push file
            when ".styl", ".css"
              project.files.styles.push file
            else
              throw "Unrecognized file extension."

    return changed

  compileFile: (file)->

    return false  if file.sourcePath in @blackList

    try
      sourceTime = Date.parse fs.statSync(file.sourcePath).mtime
    catch e
      log.info "Failed to read file #{file.sourcePath}"
      file.content = ''
      @blackList.push file.sourcePath
      return true

    if sourceTime <= file.cacheTime
      if not file.content?
        file.content = fs.readFileSync file.cachePath, "utf-8"
        if fs.existsSync file.sourceMapPath
          sourceMapJSON = fs.readFileSync file.sourceMapPath, "utf-8"
          file.sourceMap = new SourceMap.SourceMapConsumer(sourceMapJSON)._generatedMappings
      return false

    source = fs.readFileSync file.sourcePath, "utf-8"
    switch file.extension
      when ".coffee", ".js"
        if file.extension is ".coffee"
          try

            result = CoffeeScript.compile source,
              filename: file.includePath
              sourceFiles: [file.includePath]
              bare: yes
              sourceMap: yes
            js = if result.js.indexOf("pistachio") != -1
              compilePistachios(result.js).toString()
            else
              result.js

            jsSourceMap = result.v3SourceMap

            if file.includePath.indexOf("Framework") == 0
              r = /^class (\w+)/gm
              while match = r.exec source
                js += "\nKD.classes." + match[1] + " = " + match[1] + ";"


          catch error
            log.error "CoffeeScript Error in #{file.includePath}: #{(error.stack.split "\n")[0]}"
            spawn.apply null, ["say", ["coffeescript error"]]
            file.cacheTime = sourceTime # avoid repeated error
            return
        else
          js = source
          jsSourceMap = null

        if process.env.NO_UGLIFYJS
          file.content = js
          if jsSourceMap?
            fs.writeFileSync file.sourceMapPath, jsSourceMap, "utf8"
            file.sourceMap = jsSourceMap
        else
          try ast = UglifyJS.parse js
          catch e
            console.error """
              JS parse error occurred during minification: #{file.sourcePath}
              """
            throw e
          ast.figure_out_scope()
          ast = ast.transform UglifyJS.Compressor
            warnings: no
            sequences: no
            drop_debugger: no

          uglifiedSourceMap = UglifyJS.SourceMap(orig: jsSourceMap)
          stream = UglifyJS.OutputStream
            source_map: uglifiedSourceMap
          ast.print stream
          file.content = stream.toString()
          sourceMapJSON = uglifiedSourceMap.toString()
          fs.writeFileSync file.sourceMapPath, sourceMapJSON, "utf8"
          file.sourceMap = new SourceMap.SourceMapConsumer(sourceMapJSON)._generatedMappings
      when ".styl"

        rootPath = path.dirname(file.sourcePath)

        stylus = Stylus(source)
          .set('compress',true)
          .set('paths', [rootPath])
          .define('sprite', spriteHelper?.image)
          .define('sprite-dimensions', spriteHelper?.dimensions)
          .use(nib())
          .render (err, css)=> # callback is synchronous
            log.error "error with styl file at #{file.includePath}:\n #{err}"  if err
            file.content = css

      when ".css"
        file.content = source
      else
        throw "Illegal file extension: " + file.extension

    fs.writeFileSync file.cachePath, file.content, "utf8"
    file.cacheTime = sourceTime
    return true

  buildJS: (options, project)->

    # NOTE: DO NOT WRAP EVERYTHING IN A CLOSURE BY DESIGN
    # Some of our libraries expect that they'll be executed in
    # the global scope.  This can introduce subtle errant
    # behavior that can go completely undetected. C.T.
    # DON'T DO THIS:
    # js = "(function(){ "
    # serve the JS bare instead:

    js = ''
    sourceMap =
      version     : 3
      file        : project.outputs.script
      sourceRoot  : @config.client.runtimeOptions.sourceUri
      sources     : "#{file.sourceMapRoot}#{file.includePath}" for file in project.files.scripts
      names       : []
      mappings    : ""

    process.stdout.write "\n - Updating scripts for #{project.type} #{project.title} ... "
    fileLineOffset = 0
    firstInLine = true

    previousGeneratedLine = 1
    previousGeneratedColumn = 0
    previousOriginalLine = 0
    previousOriginalColumn = 0
    previousSource = 0

    for file, scriptIndex in project.files.scripts
      js += file.content + "\n"
      for mapping in (file.sourceMap ? [])
        while previousGeneratedLine < fileLineOffset + mapping.generatedLine
          sourceMap.mappings += ";"
          previousGeneratedLine++
          firstInLine = true
          previousGeneratedColumn = 0

        if not firstInLine
          sourceMap.mappings += ","
        firstInLine = false

        sourceMap.mappings += base64VLQ.encode(mapping.generatedColumn - previousGeneratedColumn)
        previousGeneratedColumn = mapping.generatedColumn

        sourceMap.mappings += base64VLQ.encode(scriptIndex - previousSource)
        previousSource = scriptIndex

        sourceMap.mappings += base64VLQ.encode(mapping.originalLine - 1 - previousOriginalLine)
        previousOriginalLine = mapping.originalLine - 1

        sourceMap.mappings += base64VLQ.encode(mapping.originalColumn - previousOriginalColumn)
        previousOriginalColumn = mapping.originalColumn

      fileLineOffset += file.content.split("\n").length

    mapUrl = project.outputs.script.replace /^website\//, ''
    js += "//# sourceMappingURL=/#{mapUrl}.map"

    filepath = project.outputs.script
    fs.writeFileSync filepath, js
    fs.writeFileSync filepath + ".map", JSON.stringify(sourceMap)

    @showFileInfo filepath, project, 'scripts' # project.outputs.script, project.files.scripts.length, scripts

  buildCSS: (options, project)->
    process.stdout.write " - Updating styles for #{project.type} #{project.title} ... "
    code = ""
    for file in project.files.styles
      code += file.content+"\n"
    filepath = project.outputs.style
    fs.writeFileSync filepath, code

    @showFileInfo filepath, project, 'styles' # project.outputs.style, project.files.styles.length, styles

  getEnvForRollbar: ->
    return if @config.client.version is "0.0.1" then "development" else "production"

  showFileInfo:(filepath, project, ptype )->

    {size} = fs.statSync filepath

    oldSize = @fileSizes[filepath]
    oldSize = if oldSize then "it was #{formatByte oldSize} and the diff is #{formatByte size - oldSize} " else ''

    # console.log project, ptype
    process.stdout.write "#{filepath}\n - Includes #{project.files[ptype].length} #{ptype}, filesize is #{formatByte size} #{oldSize} \n"
    @fileSizes[filepath] = size

  getProjects:->

    rp = (address)=>
      "#{ address?.replace /^website\//, '/' }?#{ @config.client.version }"

    apps = {}
    {projects, bundles} = require './projects'

    # Build the apps dictionary
    for own title, project of projects
      apps[title] =
        style      : rp project.style
        script     : rp project.script
        identifier : "app-#{title.toLowerCase()}"

    # Override the information based on bundles
    for own title, bundle of bundles
      for project in bundle.projects
        apps[project] =
          style      : rp bundle.style
          script     : rp bundle.script
          identifier : "app-#{title.toLowerCase()}"

    # Remove internals
    for internal in ['PostOperations', 'KDBackend', 'KDFramework', 'KDMainApp']
      delete apps[internal]

    return JSON.stringify apps

  getRoutes:->

    routesSrc = '\n'

    for own name, project of @projectsToBuild

      if fs.existsSync project.routes
        console.log "Routes added for \"#{name} App\""
        routesSrc += "#{fs.readFileSync project.routes, 'utf-8'}\n"
      else
        console.warn "No routes found for \"#{name} App\""

    return routesSrc
