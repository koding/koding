fs             = require 'fs'
path           = require 'path'
child_process  = require 'child_process'

debug          = require('debug') 'client:scripts'
build          = require 'bant-build'
through        = require 'through2'
coffeeify      = require 'coffeeify'
rewritify      = require 'rewritify'
pistachioify   = require 'pistachioify'
browserify     = require 'browserify'
watchify       = require 'watchify'
uglifyify      = require 'uglifyify'

glob           = require 'glob'
xtend          = require 'xtend'
gitrev         = require 'git-rev'
mkdirp         = require 'mkdirp'
pretty         = require 'pretty-bytes'

del            = require 'del'
merge          = require 'merge-stream'
argv           = require('minimist') process.argv

gulp           = require 'gulp'
gutil          = require 'gulp-util'
gdebug         = require 'gulp-debug'
rename         = require 'gulp-rename'
watch          = require 'gulp-watch'
styleHelper    = require './gulptasks/style'
concat         = require 'gulp-concat'

devMode        = argv.devMode?
watchMode      = argv.watchMode?
version        = argv.ver? or 1

log            = (color, message) -> gutil.log gutil.colors[color] message

modules = glob.sync('*/bant.json').map (row) -> return row.split('/')[0]


opts =
  outdir: path.resolve __dirname, '../website/a/p/p'
  baseurl: '/a/p/p'
  modules: modules
  rev: null
  browserify:
    extensions: ['.coffee', '.js', '.json']
    # debug: true
  globals:
    config: {}
    appClasses: {}
    navItems: []
    navItemIndex: []
    REMOTE_API: {}


files = []
folders = opts.modules
BUILD_PATH = opts.outdir


gulp.task 'clean', (callback) ->
  del [
    "#{BUILD_PATH}/css/*.*.css"
    "#{BUILD_PATH}/sprites/*"
    "#{__dirname}/.sprites/*"]
  , force: yes, callback


gulp.task 'default', ['styles', 'scripts'], (callback) ->
  mkdirp "#{opts.outdir}/thirdparty", (err) ->
    throw err  if err
    callback()


gulp.task 'create-dirs', (callback) ->

  mkdirp "#{opts.outdir}/thirdparty", (err) ->
    throw err  if err
    callback()


gulp.task 'set-remote-api', (callback) ->

  child_process.exec 'node get-bongo-schema.js', (err, res) ->
    debug 'could not gt bongo-schema'  if err
    opts.globals.REMOTE_API = xtend opts.globals.REMOTE_API, JSON.parse res
    callback()


gulp.task 'set-config-apps', ['set-revid'], (callback) ->
  apps = {}

  {baseurl, rev} = opts

  modules.forEach (id) ->
    name = switch id
      when 'ide' then 'IDE'
      else id.charAt(0).toUpperCase() + id.slice(1)

    apps[name] =
      identifier: id
      name: name
      style: "#{baseurl}/#{id}.css?v=#{opts.rev}"
      script: "#{baseurl}/#{id}.js?v=#{opts.rev}"

  opts.globals.config = xtend opts.globals.config, {apps}
  callback()


gulp.task 'set-revid', (callback) ->

  gitrev.short (rev) ->
    opts.rev = rev
    callback()


gulp.task 'copy-thirdparty', ['create-dirs'], (callback) ->

  i = 0

  glob 'thirdparty/**/*', nodir: yes, (err, files) ->
    i = files.length - 1

    throw err  if err

    files.forEach (file, j) ->
      return  if file is 'thirdparty/Readme.md'

      components = file.split('/').slice(0, -1).join '/'

      mkdirp "#{opts.outdir}/#{components}", (err) ->
        throw err  if err
        stream = fs.createReadStream "#{__dirname}/#{file}"
        stream.pipe fs.createWriteStream "#{opts.outdir}/#{file}"
        callback()  if i - j is 0


gulp.task 'copy-assets', ['create-dirs'], (callback) ->

  i = 0

  glob 'assets/**/*', nodir: yes, (err, files) ->
    i = files.length - 1

    throw err  if err

    files.forEach (file, j) ->
      return  if file is 'assets/Readme.md'

      components = file.split('/').slice(0, -1).join '/'

      mkdirp "#{opts.outdir}/#{components}", (err) ->
        throw err  if err
        stream = fs.createReadStream "#{__dirname}/#{file}"
        stream.pipe fs.createWriteStream "#{opts.outdir}/#{file}"
        callback()  if i - j is 0


gulp.task 'scripts', ['set-remote-api', 'set-config-apps', 'copy-thirdparty', 'copy-assets'], (callback) ->

  debug "modules:\t#{modules.join ', '}"
  debug "outdir:\t#{opts.outdir}"
  debug "rev:\t#{opts.rev}"

  mapping = {}
  modules.forEach (name) -> mapping[name] = "../#{name}/lib"

  if watchMode
    b = watchify(browserify(xtend(opts.browserify, watchify.args)))
  else
    b = browserify opts.browserify

  b.transform coffeeify, global: yes
   .transform pistachioify, global: yes
   .transform rewritify,
     global: yes
     extensions: ['coffee']
     basedir: __dirname
     mapping: mapping
  
  unless devMode
    b.transform uglifyify,
      global: yes
      mangle: yes


  bant = build b, globals: opts.globals
    .on 'bundle', (bundle) ->
      outfile = path.join opts.outdir, "#{bundle.name}.js"
      fs.writeFile outfile, bundle.source, (err, res) ->
        debug "could not write #{outfile}"  if err
        debug "#{pretty bundle.source.length} written to #{path.basename outfile}"

  b.require(require.resolve('kd.js'), { expose: 'kd' })  unless watchMode

  gulp.src(['*/bant.json']).pipe bant

  return null


gulp.task 'styles-kd', ->

  mainStream = gulp.src "#{__dirname}/node_modules/kd.js/dist/kd.css"
    .pipe gulp.dest "#{BUILD_PATH}/"

  # we need to serve the .map file as well for development - sy
  # currently we don't have it under dist

  # if devMode
  #   mapStream = gulp.src "#{__dirname}/node_modules/kd.js/dist/kd.css.map"
  #     .pipe gulp.dest "#{BUILD_PATH}/css/"

  #   return merge [mainStream, mapStream]

  # else
  #   return mainStream


unf = "AN-UNFORTUNATE-5-SECS-FOR-SPRITE-FILES-TO-BE-WRITTEN"


gulp.task 'styles', ['clean', 'styles-kd', 'sprites', unf], ->

  return merge folders.map (folder) ->

    appfnPath = "#{__dirname}/app/lib/styl/appfn.styl"

    compile = ->
      src = [ "./#{folder}/lib/**/*.styl", "!#{appfnPath}" ]
      includes = [ appfnPath, "#{__dirname}/.sprites/*/sprite@*x.styl" ]

      stream = styleHelper {
        fileName : "#{folder}.css"
        includes
        folder
        src
      }

      stream.pipe gulp.dest "#{BUILD_PATH}"
      return stream

    if devMode
      watch [ "#{__dirname}/#{folder}/**/*.styl", "!#{appfnPath}" ]
      , read : no
      , compile

    return compile()


gulp.task unf, ['sprites'], (cb) -> setTimeout cb, 5000


gulp.task 'sprites', ['clean'], ->

  return merge folders.map (folder) ->

    return merge [1,2].map (pixelRatio) ->

      generate = (pr) ->
        stream = require('./gulptasks/sprite') folder, pr
        stream.css.pipe gulp.dest "#{__dirname}/.sprites/#{folder}/"
        stream.img.pipe gulp.dest "#{BUILD_PATH}/"
        return stream

      if devMode
        watch ["#{folder}/sprites/#{pixelRatio}x/**/*"]
        , read : no
        , generate.bind(null, pixelRatio)

      return generate pixelRatio


# this is a helper task for copying folders
# not a part of the builder
gulp.task 'copy', ->

  return merge folders.map (folder) ->
    gulp.src ["./#{folder}/**/*"], base : "./#{folder}/lib/"
      .pipe gdebug title: 'unicorn:'
      .pipe gulp.dest "./../client3/#{folder}/"


gulp.task 'clean-stuff', (callback) ->
  del ["#{__dirname}/**/lib/styl/sprite@*x.styl"], callback


gulp.task 'lowercase', ->

    return merge folders.map (folder) ->
      gulp.src ["./#{folder}/**/*.coffee"], base : "./#{folder}/lib/"
        .pipe rename (path, file) ->
          contents = file.contents.toString()
          n = (/class\s([A-Z]{1}\w+)/.exec contents)?[0]
          name = n.replace 'class ', ''  if n
          console.log name.toLowerCase() if name



        # .pipe debug title: 'unicorn:'
        # .pipe gulp.dest "./../client3/#{folder}/"
