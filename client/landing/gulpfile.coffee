fs      = require 'fs'
gulp    = require 'gulp'
argv    = require('minimist') process.argv
nodemon = require 'gulp-nodemon'
req     = (module) -> require "./gulptasks/#{module}"

# CONSTANTS

SERVER_FILE = "./server/server.coffee"
SERVER_PATH = ["./server/**/*.coffee"]


# HELPERS

{watchLogger, log} = req 'helper.logger'


# BUILD SERVER

gulp.task 'serve', ['build'], -> server = nodemon script: SERVER_FILE


# WATCHERS

gulp.task 'watch-server', -> watchLogger 'cyan', gulp.watch SERVER_PATH, ['serve']


# BUILD

gulp.task 'build', ->

  folders = (folder for folder in fs.readdirSync('./') when fs.statSync(folder).isDirectory())
  sites   = folders.filter (folder) -> folder.search(/^site\./) is 0

  console.log sites

gulp.task 'default', ['build', 'serve'], ->


# ERROR HANDLING

process.on 'uncaughtException', (err)->

  log 'red', "#{err.name}: #{err.message}"
  # console.error err
