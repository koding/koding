fs           = require 'fs'
vfs          = require 'vinyl-fs'
path         = require 'path'
gloh         = require 'gloh'
defined      = require 'defined'
bant         = require 'bant'
JSONStream   = require 'JSONStream'
through      = require 'through2'
coffeeify    = require 'coffeeify'
pistachioify = require 'pistachioify'
uglifyify    = require 'uglifyify'
xtend        = require 'xtend'
async        = require 'async'
inspect      = require('util').inspect
pretty       = require 'pretty-bytes'
exorcist     = require 'exorcist'
asStream     = require 'as-stream'
notifier     = require 'node-notifier'
mkdirp       = require 'mkdirp'
nub          = require 'nub'
spritesmith  = require 'gulp.spritesmith'
chalk        = require 'chalk'
chokidar     = require 'chokidar'

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
SPRITE_TMPDIR               = '.sprites'

module.exports =

class Haydar

  constructor: (opts) ->

    opts = @_options = xtend opts,
      basedir   : defined opts.basedir, process.cwd()
      outdir    : defined opts.outdir, process.cwd()
      baseurl   : defined opts.baseurl, '/'
      defaults  : defined opts.globalsFile, {}
      cfg       : defined opts.configFile, {}
      manifests : defined opts.use, []

    opts.basedir = path.resolve __dirname, opts.basedir
    opts.outdir = path.resolve __dirname, opts.outdir

    if 'string' is typeof opts.cfg
      opts.cfg = require @_resolve(opts.cfg)

    opts.config = defined opts.cfg.config, {}
    opts.schema = defined opts.cfg.schema, {}
    opts.rev    = defined opts.config.version, '2.0'

    if opts.revId
      opts.outdir = path.join opts.outdir, opts.rev
      opts.baseurl = [ opts.baseurl, opts.rev ].join '/'

    opts.spriteTmpCssOutdir = @_resolve SPRITE_TMPDIR
    opts.spriteImgOutdir = defined opts.spriteImgOutdir, opts.outdir

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


  build: () ->
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

        pending = files.length

        @_time chalk.blue 'manifests'

        files.forEach (x) =>
          @_time 'manifests: parse ' + x

          parse = JSONStream.parse()

          s = fs.createReadStream x
          rsManifests.push s

          tr = through.obj (row, enc, cb) =>
            @_timeEnd 'manifests: parse ' + x
            row.basedir = defined row.basedir, path.dirname @_resolve(x)
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


  _build: () ->

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

    rewriteMap = appNames.reduce (acc, x) ->
      acc[x] = './' + x + '/lib/'
      return acc
    , {}

    modules = manifests.map (x) =>
      name = x.name
      if name is 'ide'
        name = 'IDE'
      else
        name = name.charAt(0).toUpperCase() + name.slice(1)

      return {
        identifier : x.name
        name       : name
        routes     : x.routes
        shortcuts  : x.shortcuts
        style      : opts.baseurl + '/' + x.name + '.css'
      }

    transforms = [ coffeeify, pistachioify ]

    if opts.minifyJs
      transforms.push [ uglifyify, {
        global      : yes
        mangle      : yes
        'screw-ie8' : yes
        #compress: { # todo: investigate these -og
          #sequences    : yes
          #dead_code    : yes
          #conditionals : yes
          #booleans     : yes
          #unused       : yes
          #if_return    : yes
          #join_vars    : yes
          #drop_console : no
        #}
      } ]

    aceBasePath = [ opts.baseurl, THIRDPARTY_OUTDIR, 'ace' ].join '/'

    opts_ =
      basedir    : opts.basedir
      debug      : opts.debugJs
      factor     : false
      extensions : [ '.coffee' ]
      transform  : transforms
      rewriteMap : rewriteMap
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
      b.on 'update', (ids) ->
        ids.forEach (x) ->
          console.log 'updated ' + x
        bundle()
    else
      b = bant opts_

    b.use manifests

    # force browser-pack to expose require
    b._bpack.hasExports = true


    bundle = =>

      start = Date.now()
      notify = @_notify.bind this
      
      b.bundle (err, src) =>

        if err
          console.error inspect(err, { colors: true })
          if not opts.watchJs
            throw err
          else
            src = 'console.error(' + JSON.stringify(String(err)) + ')'
            fs.writeFile outfile, src, (err) ->
              if err
                console.error err # wtf
              else
                console.log 'written error to ' + outfile
        else
          if opts.extractJsSourcemaps
            s = fs.createWriteStream outfile
            asStream(src).pipe(exorcist(opts.jsSourcemapsOutfile)).pipe(s)
            s.once 'finish', ->
              secs = ((Date.now() - start)/1000).toFixed 2
              msg = 'written ' + outfile + ' (' + secs + ')'
              console.log msg
              console.log 'extracted source maps to ' + opts.jsSourcemapsOutfile
              if not opts.watchJs
                done()
              else
                notify 'scripts', msg
            s.on 'error', (err) ->
              if not opts.watchJs
                throw err
              else
                console.error err
          else
            fs.writeFile outfile, src, (err, res) ->
              if err
                if not opts.watchJs
                  throw err
                else
                  console.error err
              else
                secs = ((Date.now() - start)/1000).toFixed 2
                msg = pretty(src.length) + ' written to ' + outfile + ' (' + secs + ')'
                console.log msg
                if not opts.watchJs
                  done()
                else
                  notify 'scripts', msg

    bundle()


  _styles: (done) ->
    done()


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
      files = files.filter (x) ->
        return true  unless x is 'Readme.md'

      pending = files.length

      entities = files.map (basename) ->
        file = path.join opts.dir, basename
        outfile = path.join opts.outdir, basename
        outdir = path.dirname outfile
        return {
          file: file
          outfile: outfile
          outdir: outdir
        }

      dirs = entities.map (x) ->
        return x.outdir
      
      dirs = nub dirs

      createDirs dirs, ->
        entities.forEach (x) ->
          time opts.label + ': copy ' + x.outfile
          s = fs.createReadStream x.file
          ws = fs.createWriteStream x.outfile
          s.pipe ws
          ws.once 'finish', ->
            timeEnd opts.label + ': copy ' + x.outfile
            if --pending is 0 then done()


  _sprites: (done) ->
    opts = @_options

    manifests = opts.manifests

    time = @_time.bind this
    timeEnd = @_timeEnd.bind this
    notify = @_notify.bind this

    pending = 0

    start = 0

    smith = (manifest, basedir) ->
      pending += 4 # cssStream1x, imgStream1x, cssStream2x, imgStream2x
      # ... and in the darkness you bind them

      entities = [1, 2].map (ratio) ->

        rname = ratio + 'x'

        dir = path.join basedir, rname, '**', '*.' + SPRITESMITH_IMG_EXTENSION

        imgName = manifest.name + '@' + rname + '.' + SPRITESMITH_IMG_EXTENSION
        cssName = SPRITESMITH_CSS_NAME_PREFIX + rname + '.' + SPRITESMITH_CSS_EXTENSION

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
              throw 'throwing cowardly'

        s = vfs.src(dir).pipe spritesmith opts_
        return {
          name: manifest.name
          rname: rname
          stream: s
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
            secs = ((Date.now() - start)/1000).toFixed 2
            msg = 'written sprites to ' + opts.spriteImgOutdir + ' (' + secs + ')'
            console.log msg
            if not opts.watchSprites
              done()
            else
              notify 'sprites', msg
        cssStream.on 'finish', ->
          timeEnd 'sprites: write ' + entity.name + '@' + entity.rname + ' spritesheets to ' + tmpCssOutdir
          end_()
        imgStream.on 'finish', ->
          timeEnd 'sprites: write ' + entity.name + '@' + entity.rname + ' images to ' + opts.spriteImgOutdir
          end_()


    bundle = (x) ->
      start = Date.now()

      x.sprites.forEach (basename) ->
        dir = path.join x.basedir, basename
        smith x, dir

        if opts.watchSprites
          w = chokidar.watch dir, persistent: yes
          w.on 'ready', ->
            w.on 'raw', (e, file) ->
              if e is 'modified' or e is 'deleted'
                console.log e + ' ' + file
                smith x, dir


    manifests.forEach (x) ->
      return  unless Array.isArray x.sprites

      bundle x


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

    sound = @_options.notifySound
    icon = path.resolve __dirname, '../icon.png'

    opts =
      title: 'builder/' + title
      message: msg
      sound: sound
      icon: icon

    notifier.notify opts


getFiles = (files, cwd, cb) ->
  gloh files,
    cwd: cwd
    nodir: yes
  , cb


createDirs = (dirs, cb) ->
  fns = dirs.map (x) ->
    return mkdirp.bind mkdirp, x
  async.parallel fns, (err) ->
    if err then throw err
    cb null
