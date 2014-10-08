fs      = require 'fs'
gulp    = require 'gulp'
argv    = require('minimist') process.argv
nodemon = require 'gulp-nodemon'
shell   = require 'gulp-shell'
req     = (module) -> require "./gulptasks/#{module}"

# CONSTANTS

SERVER_FILE = "./server/server.coffee"
SERVER_PATH = ["./server/**/*.coffee"]


# HELPERS

{watchLogger, log} = req 'helper.logger'


# CREATE SITE FROM BOILERPLATE

gulp.task 'site', req 'task.site'


# BUILD SERVER

gulp.task 'serve', -> server = nodemon script: SERVER_FILE


# WATCHERS

gulp.task 'watch-server', -> watchLogger 'cyan', gulp.watch SERVER_PATH, ['serve']


# BUILD

gulp.task 'build-all-sites', req 'task.build.all'


  folders  = (folder for folder in fs.readdirSync('./') when fs.statSync(folder).isDirectory())
  sites    = folders.filter (folder) -> folder.search(/^site\./) is 0
  commands = ("gulp --gulpfile ./#{site}/gulpfile.coffee build --site=#{site}" for site in sites)

  gulp.src ''
    .pipe shell commands


gulp.task 'default', ['build', 'serve'], ->


# ERROR HANDLING

process.on 'uncaughtException', (err)->

  log 'red', "#{err.name}: #{err.message}"
  # console.error err
