fs           = require 'fs'
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

JS_OUTFILE        = 'bundle.js'
THIRDPARTY_OUTDIR = 'thirdparty'
ASSETS_OUTDIR     = 'assets'

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

    if 'string' is typeof opts.defaults
      opts.defaults = require @_resolve(opts.defaults)

    if 'string' is typeof opts.manifests
      opts.manifests = [ opts.manifests ]

    opts.jsOutfile = path.join opts.outdir, JS_OUTFILE
    if opts.extractJsSourcemaps
      opts.jsSourcemapsOutfile = path.join opts.outdir, JS_OUTFILE + '.map'


  build: () ->
    opts = @_options
    dirs = [ opts.outdir ]
    createDirs dirs, =>
      @_build()


  _build: () ->

    tasks = []
    push = (name, method) =>
      @_time name
      fn = (cb) =>
        method.bind(this) =>
          @_timeEnd name
          cb null
      tasks.push fn

    push 'scripts'    , @_scripts     if @_options.scripts
    push 'styles'     , @_styles      if @_options.styles
    push 'assets'     , @_assets      if @_options.assets
    push 'thirdparty' , @_thirdparty  if @_options.thirdparty
    push 'sprites'    , @_sprites     if @_options.sprites

    @_time 'all'
    async.parallel tasks, (err, res) =>
      if err then throw err
      @_timeEnd 'all'


  _scripts: (done) ->

    opts = @_options

    b          = null
    manifests  = []
    appNames   = []
    streams    = []
    pending    = 0
    rewriteMap = null
    modules    = null
    outfile    = opts.jsOutfile
    sourcemaps = opts.sourcemapsOutfile

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

    init = =>

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
          style      : opts.baseurl + '/' + opts.rev + '/' + x.name + '.css'
        }

      transforms = [ coffeeify, pistachioify ]

      if opts.minifyJs
        transforms.push [ uglifyify, {
          global      : yes
          mangle      : yes
          'screw-ie8' : yes
          compress: {
            sequences    : yes
            dead_code    : yes
            conditionals : yes
            booleans     : yes
            unused       : yes
            if_return    : yes
            join_vars    : yes
            drop_console : no
          }
        } ]

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

      bundle()

    getFiles opts.manifests, opts.basedir,
      (err, files) =>
        throw err if err

        if not files.length then return done()

        pending = files.length

        @_time 'load manifests'

        files.forEach (x) =>
          @_time 'parse ' + x

          parse = JSONStream.parse()

          s = fs.createReadStream x
          streams.push s

          tr = through.obj (row, enc, cb) =>
            @_timeEnd 'parse ' + x
            appNames.push row.name
            row.basedir = defined row.basedir, path.dirname @_resolve(x)
            manifests.push row
            cb null
          , (cb) =>
            if --pending is 0
              @_timeEnd 'load manifests'
              init()
            cb null

          s.pipe(parse).pipe(tr)


  _styles: (done) ->
    done()


  _assets: (done) ->
    done()


  _thirdparty: (done) ->
    done()


  _sprites: (done) ->
    done()


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
