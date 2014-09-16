gulp       = require 'gulp'
gutil      = require 'gulp-util'
coffee     = require 'gulp-coffee'
rename     = require 'gulp-rename'
buffer     = require 'gulp-buffer'
stream     = require 'gulp-stream'
stylus     = require 'gulp-stylus'
rimraf     = require 'gulp-rimraf'
concat     = require 'gulp-concat'
sourcemaps = require 'gulp-sourcemaps'
argv       = require('minimist') process.argv
browserify = require 'browserify'
coffeeify  = require 'coffeeify'
source     = require 'vinyl-source-stream'
nodemon    = require 'gulp-nodemon'
pistachio  = require 'gulp-kd-pistachio-compiler'
spritesmith= require 'gulp.spritesmith'

STYLES_PATH = ['./app/styl/**/*.styl']
COFFEE_PATH = ['./app/coffee/**/*.coffee']
INDEX_PATH  = ['./app/index.html']
SERVER_FILE = './server/server.coffee'
SERVER_PATH = ['./server/**/*.coffee']
BUILD_PATH  = argv.outputDir ? 'static'

log = (color, message) -> gutil.log gutil.colors[color] message

watchLogger = (color, watcher) ->
  watcher.on 'change', (event) ->
    log color, "file #{event.path} was #{event.type}"

gulpBrowserify = (options = {}) ->
  options.extensions or= ['.coffee']
  options.debug       ?= yes
  b = browserify options
  b.transform coffeeify
  b.bundle()

gulp.task 'serve', ['build'], -> server = nodemon script: SERVER_FILE

gulp.task 'watch-server', -> watchLogger 'cyan', gulp.watch SERVER_PATH, ['serve']

gulp.task 'styles', ['sprites'], ->

  gulp.src STYLES_PATH
    .pipe stylus
      compress  : yes
      sourcemap : inline  : yes
    .pipe concat 'main.css'
    .pipe rename 'main.css'
    .pipe gulp.dest "#{BUILD_PATH}/css"


gulp.task 'sprites', ['sprites@1x', 'sprites@2x'], ->


nameStylusVars = (suffix, sprite) ->

  arr   = sprite.source_image.split '/'
  group = arr[arr.length-2]

  # this is bad, but stylus throws when you have dots in variable names
  # we shouldn't use dots in image file names - SY
  if /\./.test(sprite.name)
    log 'red', "ERROR: Dots in sprite names cause problems, pls fix: #{sprite.name}"

  name        = sprite.name.replace /\./g, '_'
  sprite.name = "#{group}_#{name}#{suffix}";

  return sprite


gulp.task 'sprites@1x', ->

  spriteStream = gulp.src 'static/sprites@1x/**/*.png'
    .pipe spritesmith
      imgName   : 'sprite@1x.png'
      cssName   : 'sprite@1x.styl'
      imgPath   : '/images/sprite@1x.png'
      algorithm : 'binary-tree'
      padding   : 5
      cssFormat : 'stylus'
      cssVarMap : nameStylusVars.bind spriteStream, ''
    .pipe gulp.dest 'static/images/'


gulp.task 'sprites@2x', ['sprites@1x'], ->

  spriteStream = gulp.src 'static/sprites@2x/**/*.png'
    .pipe spritesmith
      imgName   : 'sprite@2x.png'
      cssName   : 'sprite@2x.styl'
      imgPath   : '/images/sprite@2x.png'
      algorithm : 'binary-tree'
      padding   : 10
      cssFormat : 'stylus'
      cssVarMap : nameStylusVars.bind spriteStream, '__2x'
    .pipe gulp.dest 'static/images/'


gulp.task 'watch-styles', -> watchLogger 'cyan', gulp.watch STYLES_PATH, ['styles']

gulp.task 'coffee', ->

  gulpBrowserify
      entries : ['./app/coffee/main.coffee']
    .pipe source 'main.js'
    .pipe buffer()
    .pipe pistachio()
    .pipe sourcemaps.init loadMaps: true
    .pipe sourcemaps.write './'
    .pipe stream()
    .pipe gulp.dest "#{BUILD_PATH}/js"

gulp.task 'watch-coffee', -> watchLogger 'cyan', gulp.watch COFFEE_PATH, ['coffee']

gulp.task 'index', ->

  gulp.src INDEX_PATH
    .pipe gulp.dest "#{BUILD_PATH}"

gulp.task 'watch-index', -> watchLogger 'yellow', gulp.watch INDEX_PATH, ['index']


gulp.task 'clean', ->
  gulp.src [BUILD_PATH], read: no
    .pipe rimraf force: yes

gulp.task 'build', ['styles', 'coffee', 'index']

watchersArray = [
  'watch-styles'
  'watch-coffee'
  'watch-index'
]

gulp.task 'watchers', watchersArray

gulp.task 'watch', ['build'].concat watchersArray

gulp.task 'default', ['watch', 'serve']


process.on 'uncaughtException', (err)->

  log 'red', "#{err.name}: #{err.message}"
  # console.error err
