{spawn, exec}     = require 'child_process'
CoffeeScript      = require 'coffee-script'
fs                = require 'fs'
nib               = require 'nib'
path              = require 'path'
compilePistachios = require 'pistachio-compiler'
ProgressBar       = require 'progress'
SourceMap         = require 'source-map'
Stylus            = require 'stylus'
UglifyJS          = require 'uglify-js'

log =
  info  : console.log
  error : console.log
  debug : console.log
  warn  : console.log

module.exports = class Builder
  buildClient: (options)->
    @config = require('koding-config-manager').load("main.#{options.configFile}")
    @incluesFileTime = 0
    @compileChanged options, true

  compileChanged: (options, initial)->
    includesChanged = @readIncludesFile()

    bar = new ProgressBar 'Building client... [:bar] :percent :elapseds', {total: @scripts.length + @styles.length, width:50, incomplete:" "} if initial

    scriptsChanged = false
    for file in @scripts
      scriptsChanged |= @compileFile file
      bar.tick() if initial

    stylesChanged = false
    for file in @styles
      stylesChanged |= @compileFile file
      bar.tick() if initial

    console.log "" if initial

    @buildJS options if initial or includesChanged or scriptsChanged
    @buildCSS options if initial or includesChanged or stylesChanged
    @buildHTML options if initial

    if @config.client.watch is yes
      log.info "Watching for changes..." if initial
      setTimeout =>
        @compileChanged options, false
      , 1000

  readIncludesFile: ->
    includesFile = @config.client.includesPath + "/includes.coffee"
    time = Date.parse(fs.statSync(includesFile).mtime)
    return false if @incluesFileTime == time
    @incluesFileTime = time

    @scripts = []
    @styles = []
    for includePath in CoffeeScript.eval(fs.readFileSync(includesFile, "utf-8"))
      cachePath = ".build/" + includePath.replace(/\//g,"_")
      file = {
        includePath: includePath
        sourcePath: @config.client.includesPath + "/" + includePath
        cachePath: cachePath
        sourceMapPath: cachePath + ".map"
        cacheTime: if fs.existsSync(cachePath) then Date.parse(fs.statSync(cachePath).mtime) else 0
        extension: path.extname(includePath)
      }

      if not (path.basename(file.sourcePath) in fs.readdirSync(path.dirname(file.sourcePath)))
        log.error "File name case is wrong: " + includePath
        process.exit 1

      switch file.extension
        when ".coffee", ".js"
          @scripts.push file
        when ".styl", ".css"
          @styles.push file
        else
          throw "Unrecognized file extension."

    return true

  compileFile: (file)->
    sourceTime = Date.parse fs.statSync(file.sourcePath).mtime

    if sourceTime <= file.cacheTime
      if not file.content?
        file.content = fs.readFileSync file.cachePath, "utf-8"
        file.sourceMap = fs.readFileSync file.sourceMapPath, "utf-8" if fs.existsSync file.sourceMapPath
      return false

    source = fs.readFileSync file.sourcePath, "utf-8"
    switch file.extension
      when ".coffee", ".js"
        if file.extension == ".coffee"
          try
            result = CoffeeScript.compile source,
              filename: file.includePath
              bare: yes
              sourceMap: yes
            js = if result.js.indexOf("pistachio") != -1 
              compilePistachios(result.js).toString()
            else
              result.js

            fixedSourceMap = new SourceMap.SourceMapGenerator file: ""
            new SourceMap.SourceMapConsumer(result.v3SourceMap).eachMapping (mapping)->
              fixedSourceMap.addMapping
                generated:
                  line: mapping.generatedLine - 1
                  column: mapping.generatedColumn
                original:
                  line: mapping.originalLine
                  column: mapping.originalColumn
                source: file.includePath
            jsSourceMap = fixedSourceMap.toJSON()

            if file.includePath.indexOf("Framework") == 0
              r = /^class (\w+)/g
              while match = r.exec source
                js += "\nKD.classes." + match[1] + " = " + match[1] + ";"
          catch error
            log.error "CoffeeScript Error in #{file.includePath}: #{(error.stack.split "\n")[0]}"
            spawn.apply null, ["say", ["coffee script error"]]
            file.cacheTime = sourceTime # avoid repeated error
            return
        else
          js = source
          jsSourceMap = null

        ast = UglifyJS.parse js
        ast.figure_out_scope()
        ast = ast.transform UglifyJS.Compressor(warnings: no)
        
        uglifiedSourceMap = UglifyJS.SourceMap(orig: jsSourceMap)
        stream = UglifyJS.OutputStream source_map: uglifiedSourceMap
        ast.print stream
        file.content = stream.toString()
        file.sourceMap = uglifiedSourceMap.toString()
        fs.writeFileSync file.sourceMapPath, file.sourceMap, "utf8"
      when ".styl"
        Stylus(source).set('compress',true).use(nib()).render (err, css)=> # callback is synchronous
          log.error "error with styl file at #{file.includePath}" if err
          file.content = css
      when ".css"
        file.content = source
      else
        throw "Illegal file extension: " + file.extension

    fs.writeFileSync file.cachePath, file.content, "utf8"
    file.cacheTime = sourceTime
    return true

  buildJS: (options)->
    js = "var KD = {}; KD.config = #{JSON.stringify(@config.client.runtimeOptions)}; (function(){ "
    lineOffset = 0
    sourceMap = new SourceMap.SourceMapGenerator file: @config.client.js, sourceRoot: @config.client.runtimeOptions.sourceUri
    for file in @scripts
      contentLineCount = file.content.split("\n").length
      new SourceMap.SourceMapConsumer(file.sourceMap).eachMapping (mapping)->
        sourceMap.addMapping
          generated:
            line: lineOffset + mapping.generatedLine
            column: mapping.generatedColumn
          original:
            line: mapping.originalLine
            column: mapping.originalColumn
          source: file.includePath
      js += file.content + "\n"
      lineOffset += contentLineCount
    js += "}).call(this);\n//@ sourceMappingURL=/#{@config.client.js}.map"

    fs.writeFileSync @config.client.websitePath + "/" + @config.client.js, js
    fs.writeFileSync @config.client.websitePath + "/" + @config.client.js + ".map", sourceMap.toString()
    log.info "Build complete: #{@config.client.js}"

  buildCSS: (options)->
    code = ""
    for file in @styles
      code += file.content+"\n"
    fs.writeFileSync @config.client.websitePath + "/" + @config.client.css, code
    log.info "Build complete: #{@config.client.css}"

  buildHTML: (options)->
    index = fs.readFileSync @config.client.includesPath + "/" + @config.client.indexMaster, 'utf-8'
    index = index.replace "js/kd.js", "js/kd.#{@config.client.version}.js?" + Date.now()
    index = index.replace "css/kd.css", "css/kd.#{@config.client.version}.css?" + Date.now()
    if @config.client.useStaticFileServer is no
      st = "https://api.koding.com"  # CHANGE THIS TO SOMETHING THAT MAKES SENSE tbd
      index = index.replace ///#{st}///g,""
      # log.warn "Static files will be served from NodeJS process. (because -d vpn is used - ONLY DEVS should do this.)"
    fs.writeFileSync @config.client.websitePath + "/" + @config.client.index, index
    log.info "Build complete: #{@config.client.index}"
