gulp       = require 'gulp'
gutil      = require 'gulp-util'
coffee     = require 'gulp-coffee'
rename     = require 'gulp-rename'
stylus     = require 'gulp-stylus'
rimraf     = require 'gulp-rimraf'
concat     = require 'gulp-concat'
sourcemaps = require 'gulp-sourcemaps'
argv       = require('minimist') process.argv
browserify = require 'browserify'
coffeeify  = require 'coffeeify'
source     = require 'vinyl-source-stream'
nodemon    = require 'gulp-nodemon'

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

gulpBrowserify = (options) ->
  options.extensions or= ['.coffee']
  b = browserify options
  b.transform coffeeify
  b.bundle()

gulp.task 'serve', ['build'], ->
  server = nodemon script: SERVER_FILE

gulp.task 'watch-server', -> watchLogger 'cyan', gulp.watch SERVER_PATH, ['serve']

gulp.task 'styles', ->

  gulp.src STYLES_PATH
    .pipe stylus()
    .pipe rename "main.css"
    .pipe gulp.dest "#{BUILD_PATH}/css"

gulp.task 'watch-styles', -> watchLogger 'cyan', gulp.watch STYLES_PATH, ['styles']

gulp.task 'coffee', ->

  gulpBrowserify
      entries : ['./app/coffee/main.coffee']
    .pipe source "main.js"
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
