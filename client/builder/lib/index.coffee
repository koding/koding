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

module.exports = (opts) ->

  if not opts then opts = {}

  time = (x) ->
    return  unless opts.verbose
    console.time x

  timeEnd = (x) ->
    return  unless opts.verbose
    console.timeEnd x

  resolve = (file) ->
    return path.resolve basedir, file

  manifests = defined opts.use, []
  basedir = defined opts.basedir, process.cwd()
  baseurl = defined opts.baseurl, '/a/p/p/'
  defaults = defined opts.globalsFile, {}
  cfg = defined opts.configFile, {}
  
  if 'string' is typeof defaults
    defaults = require resolve(defaults)

  if 'string' is typeof cfg
    cfg = require resolve(cfg)
    config = defined cfg.config, {}
    schema = defined cfg.schema, {}
    rev = defined config.version, '2.0'
  else
    rev = '2.0'
    schema = {}
    config = {}
  
  # --use can be set multiple times
  if 'string' is typeof manifests
    manifests = [ manifests ]

  console.time 'load manifests'

  gloh manifests,
    cwd: basedir
  , (err, files) ->
    throw err if err

    b = null
    pending = files.length
    manifests = []
    appNames = []
    streams = []

    init = ->

      rewriteMap = appNames.reduce (acc, x) ->
        acc[x] = './' + x + '/lib/'
        return acc
      , {}

      modules = manifests.map (x) ->
        name = x.name
        if name is 'ide'
          name = 'IDE'
        else
          name = name.charAt(0).toUpperCase() + name.slice(1)

        return {
          identifier: x.name
          name: name
          routes: x.routes
          shortcuts: x.shortcuts
          style: baseurl + x.name + '-' + rev + '.css'
        }

      opts =
        basedir: basedir
        debug: opts.debugJs
        factor: false
        extensions: [ '.coffee' ]
        transform: [ coffeeify, pistachioify ]
        rewriteMap: rewriteMap
        globals: xtend defaults, {
          modules: modules
          REMOTE_API: schema
        }

      b = bant opts
      b.use manifests
      # force browser-pack to expose require
      b._bpack.hasExports = true

    bundle = ->
      time 'bundle ' + outfile

    files.forEach (x) ->
      time 'parse ' + x

      parse = JSONStream.parse()

      s = fs.createReadStream x
      streams.push s

      tr = through.obj (row, enc, cb) ->
        timeEnd 'parse ' + x
        appNames.push row.name
        manifests.push row
        cb null
      , (cb) ->
        if --pending is 0
          timeEnd 'load manifests'
          init()
        cb null

      s.pipe(parse).pipe(tr)
