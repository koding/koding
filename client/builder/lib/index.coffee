fs            = require 'fs'
vfs           = require 'vinyl-fs'
path          = require 'path'
gloh          = require '@koding/gloh'
defined       = require 'defined'
bant          = require '@koding/bant'
JSONStream    = require 'JSONStream'
through       = require 'through2'
coffeeify     = require 'coffeeify'
pistachioify  = require 'pistachioify'
reactify      = require 'coffee-reactify'
uglifyify     = require 'uglifyify'
xtend         = require 'xtend'
async         = require 'async'
inspect       = require('util').inspect
pretty        = require 'pretty-bytes'
exorcist      = require 'exorcist'
asStream      = require 'as-stream'
notifier      = require 'node-notifier'
mkdirp        = require 'mkdirp'
nub           = require 'nub'
gulp          = require 'gulp'
plumber       = require 'gulp-plumber'
i18next       = require 'i18next-parser'
spritesmith   = require 'gulp.spritesmith'
chalk         = require 'chalk'
chokidar      = require 'chokidar'
rewireify     = require 'rewireify'
events        = require 'events'
nib           = require 'nib'
stylus        = require 'gulp-stylus'
concat        = require 'gulp-concat'
throttle      = require 'throttleit'
child_process = require 'child_process'
collapse      = require 'bundle-collapser/plugin'
convert       = require 'convert-source-map'
globby        = require 'globby'
babelify      = require 'babelify'
cssModulesify = require 'css-modulesify'


JS_OUTFILE                  = 'bundle.js'
THIRDPARTY_OUTDIR           = 'thirdparty'
ASSETS_OUTDIR               = 'assets'
CSS_OUTDIR                  = 'css'
SPRITESMITH_CSS_FORMAT      = 'stylus'
SPRITESMITH_IMG_EXTENSION   = 'png'
SPRITESMITH_CSS_EXTENSION   = 'styl'
SPRITESMITH_ALGORITHM       = 'binary-tree'
SPRITESMITH_PADDING         = 5
SPRITESMITH_CSS_NAME_PREFIX = 'sprite@'
SPRITES_TMPDIR              = '.sprites'
STYLES_KDJS_MODULE_NAME     = 'kd.js'
STYLES_KDJS_CSS_FILE        = 'dist/kd.css'
STYLES_COMMONS_GLOB         = 'app/styl/**/*.styl'
THROTTLE_WAIT               = 500

BUILDER_PATH = path.join __dirname, '..'

module.exports = class Haydar extends events.EventEmitter

  constructor: (opts) ->

    super()

    opts = @_options = xtend opts,
      basedir   : defined opts.basedir, process.cwd()
      outdir    : defined opts.outdir, process.cwd()
      baseurl   : defined opts.baseurl, '/'
      defaults  : defined opts.globalsFile, {}
      config    : defined opts.configFile, {}
      schema    : defined opts.schemaFile, {}
      manifests : defined opts.use, []

    opts.basedir = path.resolve __dirname, opts.basedir
    opts.outdir = path.resolve __dirname, opts.outdir

    if 'string' is typeof opts.config
      opts.config = require @_resolve opts.config

    if 'string' is typeof opts.schema
      opts.schema = require @_resolve opts.schema

    opts.rev    = defined opts.config.rev, '2.0'

    if opts.revId
      opts.outdir  = path.join opts.outdir, opts.rev
      opts.baseurl = "#{opts.baseurl}/#{opts.rev}"

    opts.spriteTmpCssOutdir = @_resolve SPRITES_TMPDIR
    opts.spriteImgOutdir = defined opts.spriteImgOutdir, opts.outdir

    opts.stylesOutdir = defined opts.stylesOutdir, opts.outdir

    if 'string' is typeof opts.defaults
      opts.defaults = require @_resolve(opts.defaults)

    if 'string' is typeof opts.manifests
      opts.manifests = [ opts.manifests ]

    opts.jsOutfile = path.join opts.outdir, JS_OUTFILE
    if opts.extractJsSourcemaps
      opts.jsSourcemapsOutfile = path.join opts.outdir, JS_OUTFILE + '.map'

    if opts.thirdparty
      if 'string' is typeof opts.thirdpartyDir
        opts.thirdpartyDir = @_resolve opts.thirdpartyDir
        opts.thirdpartyOutdir = path.join opts.outdir, THIRDPARTY_OUTDIR
      else
        opts.thirdparty = false

    if opts.assets
      if 'string' is typeof opts.assetsDir
        opts.assetsDir = @_resolve opts.assetsDir
        opts.assetsOutdir = path.join opts.outdir, ASSETS_OUTDIR
      else
        opts.assets = false


  build: ->
    opts = @_options

    manifests   = []
    rsManifests = []

    pending = 0

    dirs = [ opts.outdir ]

    getFiles opts.manifests, opts.basedir,
      (err, files) =>
        throw err if err

        if not files.length
          return console.log 'could not find ' + opts.manifests

        if opts.excludeTestrunner
          files = (file for file in files when not /testrunner/.test file)

        pending = files.length

        @_time chalk.blue 'manifests'

        files.forEach (file) =>
          @_time 'manifests: parse ' + file

          parse = JSONStream.parse()

          s = fs.createReadStream file
          rsManifests.push s

          tr = through.obj (row, enc, cb) =>
            @_timeEnd 'manifests: parse ' + file
            row.basedir = defined row.basedir, path.dirname @_resolve(file)
            manifests.push row
            cb null
          , (cb) =>
            if --pending is 0
              @_timeEnd chalk.blue 'manifests'
              createDirs dirs, =>
                opts.manifests = manifests
                opts.rsManifests = rsManifests
                @_build()
            cb()

          s.pipe(parse).pipe(tr)


  _build: ->

    tasks = []
    push = (name, method) =>
      @_time chalk.green name
      fn = (cb) =>
        method.bind(this) =>
          @_timeEnd chalk.green name
          cb null
      tasks.push fn

    push 'scripts'    , @_scripts     if @_options.scripts
    push 'styles'     , @_styles      if @_options.styles
    push 'assets'     , @_assets      if @_options.assets
    push 'thirdparty' , @_thirdparty  if @_options.thirdparty
    push 'sprites'    , @_sprites     if @_options.sprites

    @_time chalk.green 'all'
    async.parallel tasks, (err, res) =>
      if err then throw err
      @_timeEnd chalk.green 'all'


  _scripts: (done) ->

    opts = @_options

    time = @_time.bind this
    timeEnd = @_timeEnd.bind this

    b          = null

    manifests  = opts.manifests
    appNames   = manifests.map (x) -> return x.name
    streams    = opts.rsManifests
    outfile    = opts.jsOutfile
    sourcemaps = opts.sourcemapsOutfile

    rewriteMap = appNames.reduce (acc, appName) ->
      acc[appName] = "./#{appName}/lib/"
      return acc
    , {}

    rewriteMap['component-lab'] = "./component-lab/"

    modules = manifests.map (manifest) ->
      name = manifest.name
      if name is 'ide'
        name = manifest.name.toUpperCase()
      else
        name = name.charAt(0).toUpperCase() + name.slice(1)

      return {
        identifier : manifest.name
        name       : name
        routes     : manifest.routes
        shortcuts  : manifest.shortcuts
        style      : "#{opts.baseurl}/#{manifest.name}.css"
      }

    # we are only using this transform to output from cjsx to coffee
    # the rest will be handled by coffeescript compiler itself.
    _reactify = [ reactify, { coffeeout: yes } ]

    _babelify = [ babelify, {
      presets: ['es2015', 'react']
      extensions: ['.js', '.es6', '.es6.js', '.jsx']
    }]

    transforms = [ _reactify, coffeeify, pistachioify, _babelify ]

    unless opts.excludeTestrunner
      transforms.push rewireify

    if opts.minifyJs
      transforms.push [ uglifyify, {
        global      : yes
        mangle      : yes
        'screw-ie8' : yes
      } ]

    aceBasePath = "#{opts.baseurl}/#{THIRDPARTY_OUTDIR}/ace"

    opts_ =
      basedir     : opts.basedir
      debug       : opts.debugJs
      factor      : no
      extensions  : [ '.coffee', 'js', '.es6', '.es6.js', 'jsx' ]
      transform   : transforms
      rewriteMap  : rewriteMap
      ignoreWatch : ['**/node_modules/**']
      noParse     : [
        'jquery',
        'underscore',
        'lodash',
        'emojify',
        'kd-shim-algoliasearch', 'algoliasearch',
        'accounting',
        'timeago'
      ]
      globals    : xtend opts.defaults, {
        modules    : modules
        REMOTE_API : opts.schema
        acePath: [ aceBasePath, '_ace.js' ].join '/'
        aceConfig: {
          basePath: aceBasePath
          themePath: aceBasePath
          modePath: aceBasePath
          workerPath: aceBasePath
        }
      }

    if opts.watchJs
      b = bant.watch opts_

      onUpdate = (files) ->
        files.forEach (file) -> console.log "updated #{file}"
        bundle()

      onUpdate = throttle onUpdate, THROTTLE_WAIT
      b.on 'update', onUpdate
    else
      b = bant opts_

    b.require require.resolve('kd.js'), { expose: 'kd' }
    b.use manifests

    if opts.collapseJs then b.plugin collapse

    b.plugin cssModulesify,
      rootDir: opts.basedir
      output: path.join opts.stylesOutdir, 'modules.css'
      before: [
        require('postcss-mixins'),
      ]

    # force browser-pack to expose require
    b._bpack.hasExports = true

    notify = @_notify.bind this

    handleError = (err) ->
      if opts.watchJs
      then console.error inspect err, { colors: on }
      else throw err

    handleSuccess = (msg) ->
      if opts.watchJs
      then console.log(msg); notify('scripts', msg)
      else done()

    do bundle = ->

      b.bundle (err, src) ->

        return handleError err  if err
        return  unless src

        if opts.extractJsSourcemaps
          writeJSSourcemaps src, outfile, opts.jsSourcemapsOutfile, { handleSuccess, handleError }
          return

        writeJS src, outfile, { handleSuccess, handleError }


  _styles: (done) ->
    opts = @_options

    time    = @_time.bind this
    timeEnd = @_timeEnd.bind this
    notify  = @_notify.bind this

    manifests    = opts.manifests
    watchingKd   = no
    watchedGlobs = {}

    commons  = path.join opts.basedir, STYLES_COMMONS_GLOB
    includes = [ commons ]

    pending = 0
    start   = 0


    copyKd = (callback) ->
      kdPath = path.dirname require.resolve STYLES_KDJS_MODULE_NAME
      kdPath = kdPath.match(new RegExp('(.+)/'+STYLES_KDJS_MODULE_NAME))[1]
      kdCssFile = path.join kdPath, STYLES_KDJS_MODULE_NAME, STYLES_KDJS_CSS_FILE

      rs = fs.createReadStream kdCssFile

      kdCssBasename = STYLES_KDJS_CSS_FILE.split('/').slice(-1)[0]
      outfile = path.join opts.outdir, kdCssBasename

      time 'styles: kd: copy ' + outfile

      ws = fs.createWriteStream outfile
      rs.pipe ws

      ws.on 'finish', ->
        timeEnd 'styles: kd: copy ' + outfile
        msg = 'copied kd.css to ' + outfile
        console.log msg
        if opts.watchCss
          notify 'styles', msg

        callback?()

      if opts.watchCss and not watchingKd
        watchingKd = yes
        w = chokidar.watch kdCssFile, { persistent: yes }
        w.on 'change', copyKd


    styl = (manifest, globs) ->
      pending += 1

      opts_ =
        use       : nib()
        compress  : if opts.minifyCss then yes else no
        import    : includes
        define    :
          assetsPath: "#{opts.baseurl}/#{ASSETS_OUTDIR}"
        sourcemap :
          inline: if opts.debugCss then yes else no

      basename = manifest.name + '.css'
      outfile = path.join opts.stylesOutdir, basename

      time 'styles: write ' + outfile

      rs = vfs.src globs
      rs = rs.pipe stylus opts_
      rs = rs.pipe concat basename
      ws = vfs.dest opts.stylesOutdir

      rs.pipe ws

      ws.on 'finish', ->
        timeEnd 'styles: write ' + outfile

        if --pending is 0
          secs = ((Date.now() - start) / 1000).toFixed 2
          msg = "written styles to #{opts.stylesOutdir} (#{secs})"
          console.log msg

          if not opts.watchCss
            done()
          else
            notify 'styles', msg


    bundle = (manifest) ->
      start = Date.now()
      globs = []
      manifest.styles.forEach (glob) ->

        glob  = path.join manifest.basedir, glob
        globs.push glob

      onRaw = (e, file) ->

        return  unless file

        if e in ['change', 'modified', 'deleted']
          console.log "New '#{e}' event on #{file}"
          start = Date.now()
          styl manifest, globs

      onRaw = throttle onRaw, THROTTLE_WAIT

      styl manifest, globs

      files = globs.reduce (acc, glob) ->
        acc.concat globby.sync glob
      , []

      if opts.watchCss and not watchedGlobs[globs.join()]
        watchedGlobs[globs.join()] = yes
        globs.forEach (glob) -> console.log "watching #{glob}"
        w = chokidar.watch files, { persistent: yes }
        w.on 'ready', -> w.on 'raw', onRaw


    bunldeAllStyles = ->
      manifests.forEach (manifest) ->
        return  unless Array.isArray manifest.styles
        bundle manifest

    init = =>
      @on '_updated-sprites', bunldeAllStyles
      copyKd bunldeAllStyles

      return  unless opts.watchCss

      commonsWatcher = chokidar.watch includes, { persistent: yes }
      commonRaw = (e, file) ->

        return  unless file

        if e in ['change', 'modified', 'deleted']
          console.log 'updating all styles because common styles has changed!'
          bunldeAllStyles()

      commonsWatcher.on 'ready', -> commonsWatcher.on 'raw', throttle commonRaw, THROTTLE_WAIT


    if opts.sprites
      spriteSheets = path.join opts.spriteTmpCssOutdir, '*', \
        SPRITESMITH_CSS_NAME_PREFIX + '*x.' + SPRITESMITH_CSS_EXTENSION
      includes.push spriteSheets
      @once '_updated-sprites', init
    else
      init()



  _thirdparty: (done) ->
    opts = @_options
    @_copy {
      label: 'thirdparty'
      dir: opts.thirdpartyDir
      outdir: opts.thirdpartyOutdir
    }, ->
      done()


  _assets: (done) ->
    opts = @_options
    @_copy {
      label: 'assets'
      dir: opts.assetsDir
      outdir: opts.assetsOutdir
    }, ->
      done()


  _copy: (opts, done) ->
    time = @_time.bind this
    timeEnd = @_timeEnd.bind this

    getFiles [ '**/*' ], opts.dir, (err, files) ->
      files = files.filter (basename) ->
        return true  unless basename is 'Readme.md'

      pending = files.length

      rows = files.map (basename) ->
        file = path.join opts.dir, basename
        outfile = path.join opts.outdir, basename
        outdir = path.dirname outfile
        return {
          file: file
          outfile: outfile
          outdir: outdir
        }

      dirs = rows.map (row) ->
        return row.outdir

      dirs = nub dirs

      createDirs dirs, ->
        rows.forEach (row) ->
          time opts.label + ': copy ' + row.outfile
          s = fs.createReadStream row.file
          ws = fs.createWriteStream row.outfile
          s.pipe ws
          ws.once 'finish', ->
            timeEnd opts.label + ': copy ' + row.outfile
            if --pending is 0 then done()


  _sprites: (done) ->
    opts = @_options

    time    = @_time.bind this
    timeEnd = @_timeEnd.bind this
    notify  = @_notify.bind this
    emit    = @emit.bind this

    manifests = opts.manifests

    pending = 0
    start   = 0

    smith = (manifest, basedir) ->
      pending += 4 # cssStream1x, imgStream1x, cssStream2x, imgStream2x
      # ... and in the darkness you bind them

      entities = [1, 2].map (ratio) ->

        rname = "#{ratio}x"

        files = path.join basedir, rname, '**', "*.#{SPRITESMITH_IMG_EXTENSION}"

        imgName = "#{manifest.name}@#{rname}.#{SPRITESMITH_IMG_EXTENSION}"
        cssName = "#{SPRITESMITH_CSS_NAME_PREFIX}#{rname}.#{SPRITESMITH_CSS_EXTENSION}"

        opts_ =
          algorithm : SPRITESMITH_ALGORITHM
          padding   : SPRITESMITH_PADDING
          cssFormat : SPRITESMITH_CSS_FORMAT
          cssName   : cssName
          imgName   : imgName
          imgPath   : [ opts.baseurl, imgName].join '/'
          cssVarMap: (sprite) ->
            if /\./.test sprite.name
              console.error chalk.red('sprites') + ': stylus hates it when you have dots in image filenames, fix this: ' + sprite.name
              throwingCowardly = 'throwing cowardly'
              throw throwingCowardly

            sprite.name = "#{rname}_#{manifest.name}_#{sprite.name}"
            return sprite

        s = vfs.src(files).pipe spritesmith opts_
        return {
          name   : manifest.name
          rname  : rname
          stream : s
        }

      entities.forEach (entity) ->
        s = entity.stream
        tmpCssOutdir = path.join opts.spriteTmpCssOutdir, manifest.name
        time 'sprites: write ' + entity.name + '@' + entity.rname + ' spritesheets to ' + tmpCssOutdir
        time 'sprites: write ' + entity.name + '@' + entity.rname + ' images to ' + opts.spriteImgOutdir
        cssStream = s.css.pipe vfs.dest tmpCssOutdir
        imgStream = s.img.pipe vfs.dest opts.spriteImgOutdir
        end_ = ->
          if --pending is 0
            secs = ((Date.now() - start) / 1000).toFixed 2
            msg = 'written sprites to ' + opts.spriteImgOutdir + ' (' + secs + ')'
            console.log msg
            if not opts.watchSprites
              done()
            else
              notify 'sprites', msg
            emit '_updated-sprites'
        cssStream.on 'finish', ->
          timeEnd 'sprites: write ' + entity.name + '@' + entity.rname + ' spritesheets to ' + tmpCssOutdir
          end_()
        imgStream.on 'finish', ->
          timeEnd 'sprites: write ' + entity.name + '@' + entity.rname + ' images to ' + opts.spriteImgOutdir
          end_()


    bundle = (manifest) ->
      start = Date.now()

      manifest.sprites.forEach (basename) ->
        dir = path.join manifest.basedir, basename

        onRaw = (e, file) ->
          return  unless file
          if e is 'modified' or e is 'deleted'
            console.log "updated #{file}"
            start = Date.now()
            smith manifest, dir

        onRaw = throttle onRaw, THROTTLE_WAIT

        smith manifest, dir

        if opts.watchSprites
          w = chokidar.watch dir, { persistent: yes }
          w.on 'ready', ->
            w.on 'raw', onRaw


    manifests.forEach (manifest) ->
      return  unless Array.isArray manifest.sprites
      bundle manifest


  _time: (msg) ->
    return  unless @_options.verbose
    console.time msg


  _timeEnd: (msg) ->
    return  unless @_options.verbose
    console.timeEnd msg


  _resolve: (file) ->
    return  path.resolve @_options.basedir, file


  _notify: (title, msg) ->
    return  unless @_options.notify

    @_notifyQueue = defined @_notifyQueue, []

    fn = (title, msg) =>
      @_notifyShowing = true
      sound = @_options.notifySound
      icon = path.resolve __dirname, '../icons/' + title + '.png'

      opts =
        title: 'builder/' + title
        message: msg
        sound: sound
        icon: icon
        wait: false

      notifier.notify opts
      notifier.once 'timeout', =>
        @_notifyShowing = false
        if @_notifyQueue.length
          arr = @_notifyQueue.shift()
          fn.apply this, arr

    if not @_notifyShowing
      fn title, msg
    else
      @_notifyQueue.push [title, msg]



getFiles = (files, cwd, cb) ->
  gloh files,
    cwd: cwd
    nodir: yes
  , cb


createDirs = (dirs, cb) ->
  fns = dirs.map (dir) ->
    return mkdirp.bind mkdirp, dir
  async.parallel fns, (err) ->
    throw err  if err
    cb null

writeError = (err) ->

  src = "console.error('#{JSON.stringify String err}')"
  fs.writeFile outfile, src, (err) ->
    if err
    then console.error err
    else console.log "written error to #{outfile}"


writeJSSourcemaps = (src, outfile, jsSourcemapsOutfile, callbacks) ->

  start = Date.now()

  s = fs.createWriteStream outfile
  asStream(src).pipe(exorcist(jsSourcemapsOutfile)).pipe(
    asStream(convert.removeMapFileComments(src.toString()))
  ).pipe(s)

  s.once 'finish', ->
    secs = ((Date.now() - start) / 1000).toFixed 2
    msg = "written #{outfile} (#{secs} secs)"
    console.log msg
    console.log "extracted source maps to #{jsSourcemapsOutfile}"
    callbacks.handleSuccess msg

  s.on 'error', callbacks.handleError


writeJS = (src, outfile, callbacks) ->

  start = Date.now()

  try
    fs.writeFileSync outfile, src, 'utf8'
  catch e
    return callbacks.handleError err

  secs = ((Date.now() - start) / 1000).toFixed 2
  msg = "#{pretty(src.length)} written to #{outfile} (#{secs})"
  callbacks.handleSuccess msg

  # relative to compiled javascript file, i.e. bundle.js
  relLocalesPath = '../../../i18n'

  # absolute path of locale files
  absLocalesPath = path.resolve __dirname, '../../website/a/i18n'

  gulp.src outfile
    .pipe plumber()
    .pipe i18next
      output: relLocalesPath
      locales: [ 'en', 'tr' ]
      functions: [ '__t', '_t' ]
      namespace: 'default'
      keySeparator: '..'
      namespaceSeparator: '::'
    .pipe gulp.dest absLocalesPath
