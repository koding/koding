{spawn, exec}     = require 'child_process'
CoffeeScript      = require 'coffee-script'
ExecSync          = require 'execSync'
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
    @files = []
    @scripts = []
    @styles = []
    for includePath in require("../" + @config.client.includesPath + "/includes.coffee")
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

      @files.push file
      switch file.extension
        when ".coffee", ".js"
          @scripts.push file
        when ".styl", ".css"
          @styles.push file
        else
          throw "Unrecognized file extension."

    ExecSync.code """grep "^class " client/Framework/* -R | awk '{split($0,a,":"); split(a[2], b, " "); print "KD.classes."b[2]"="b[2];}' | uniq > ./client/Framework/classregistry.coffee"""
    @compileChanged options, true

  compileChanged: (options, initial)->
    bar = new ProgressBar 'Building client... [:bar] :percent :elapseds', {total: @files.length, width:50, incomplete:" "} if initial
    changed = false
    for file in @files
      changed |= @compileFile file
      bar.tick() if initial
    console.log "" if initial

    if changed
      @buildJS options
      @buildCSS options
      @buildHTML options
      log.info "Done building client."
      if require("os").platform() is 'linux'
        exec "notify-send \"Koding instance updated\""

    if @config.client.watch is yes
      log.info "Watching for changes..." if initial
      setTimeout =>
        @compileChanged options, false
      , 1000

  compileFile: (file)->
    sourceTime = Date.parse fs.statSync(file.sourcePath).mtime

    if sourceTime <= file.cacheTime
      if not file.content?
        file.content = fs.readFileSync file.cachePath, "utf-8"
        file.sourceMap = fs.readFileSync file.sourceMapPath, "utf-8" if fs.existsSync file.sourceMapPath
      return false

    content = fs.readFileSync file.sourcePath, "utf-8"
    sourceMap = null
    if file.extension == ".coffee"
      try
        result = CoffeeScript.compile content,
          filename: file.includePath
          bare: yes
          sourceMap: yes
        content = result.js
        sourceMap = result.v3SourceMap
      catch error
        log.error "CoffeeScript Error in #{file.includePath}: #{(error.stack.split "\n")[0]}"
        spawn.apply null, ["say", ["coffee script error"]]
        file.cacheTime = sourceTime # avoid repeated error
        return

    if file.extension == ".coffee" || file.extension == ".js"
      content = compilePistachios(content).toString() if content.indexOf("pistachio") != -1

      if sourceMap?
        fixedSourceMap = new SourceMap.SourceMapGenerator file: ""
        new SourceMap.SourceMapConsumer(sourceMap).eachMapping (mapping)->
          if mapping.generatedLine > 1 && mapping.originalLine > 0
            fixedSourceMap.addMapping
              generated:
                line: mapping.generatedLine - 1
                column: mapping.generatedColumn
              original:
                line: mapping.originalLine
                column: mapping.originalColumn
              source: file.includePath
        sourceMap = fixedSourceMap.toJSON()

      ast = UglifyJS.parse content
      ast.figure_out_scope()
      ast = ast.transform UglifyJS.Compressor(warnings: no)
      
      sourceMap = UglifyJS.SourceMap(orig: sourceMap)
      stream = UglifyJS.OutputStream source_map: sourceMap
      ast.print stream
      content = stream.toString()
      sourceMap = sourceMap.toString()
    
    if file.extension == ".styl"
        Stylus(content).set('compress',true).use(nib()).render (err, css)=> # callback is synchronous
          log.error "error with styl file at #{file.includePath}" if err
          content = css

    fs.writeFileSync file.cachePath, content, "utf8"
    fs.writeFileSync file.sourceMapPath, sourceMap, "utf8" if sourceMap?

    file.content = content
    file.sourceMap = sourceMap
    file.cacheTime = sourceTime
    return true

  buildJS: (options)->
    js = "var KD = {}; KD.config = " + JSON.stringify(@config.client.runtimeOptions) + "; (function(){ "
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
    js += "}).call(this);\n//@ sourceMappingURL=/" + @config.client.js + ".map"

    fs.writeFileSync @config.client.websitePath + "/" + @config.client.js, js
    fs.writeFileSync @config.client.websitePath + "/" + @config.client.js + ".map", sourceMap.toString()

  buildCSS: (options)->
    code = ""
    for file in @styles
      code += file.content+"\n"
    fs.writeFileSync @config.client.websitePath + "/" + @config.client.css, code

  buildHTML: (options)->
    index = fs.readFileSync @config.client.includesPath + "/" + @config.client.indexMaster, 'utf-8'
    index = index.replace "js/kd.js", "js/kd.#{@config.client.version}.js?" + Date.now()
    index = index.replace "css/kd.css", "css/kd.#{@config.client.version}.css?" + Date.now()
    if @config.client.useStaticFileServer is no
      st = "https://api.koding.com"  # CHANGE THIS TO SOMETHING THAT MAKES SENSE tbd
      index = index.replace ///#{st}///g,""
      # log.warn "Static files will be served from NodeJS process. (because -d vpn is used - ONLY DEVS should do this.)"
    fs.writeFileSync @config.client.websitePath + "/" + @config.client.index, index
