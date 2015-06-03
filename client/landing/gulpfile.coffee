fs      = require 'fs'
gulp    = require 'gulp'
shell   = require 'gulp-shell'
prompt  = require 'gulp-prompt'
nodemon = require 'gulp-nodemon'
argv    = require('minimist') process.argv
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


# DEFAULT

gulp.task 'default', ->

  console.log '\n'

  folders  = (folder for folder in fs.readdirSync('./') when fs.statSync(folder).isDirectory())
  sites    = folders
    .filter (folder) -> folder.search(/^site\./) is 0 and folder isnt 'site.boilerplate'
    .map (folder) -> folder.replace 'site.', ''

  firstOptions = ['Build an existing site', 'Create a new site']

  gulp.src ''
    .pipe prompt.prompt [
      type    : 'list'
      name    : 'createOrBuild'
      message : 'Would you like to create a new site or build an existing one?'
      choices : firstOptions
    ,
      when    : (answer) -> answer.createOrBuild is firstOptions[1]
      type    : 'input'
      name    : 'newSite'
      message : 'Type a name for the new site:'
    ,
      when    : (answer) -> answer.createOrBuild is firstOptions[0]
      type    : 'list'
      name    : 'siteName'
      message : 'Choose the site you want to build?'
      choices : sites
    ,
      when    : (answer) -> answer.siteName
      type    : 'confirm'
      name    : 'uglify'
      default : no
      message : 'Do you want to uglify javascript?'
    ,
      when    : (answer) -> answer.siteName
      type    : 'confirm'
      name    : 'watch'
      message : 'Do you want to watch for changes?'
    ,
      when    : (answer)-> answer.watch
      type    : 'confirm'
      name    : 'serve'
      message : 'Do you want to run the server?'
    ,
      when    : (answer)-> answer.serve
      type    : 'list'
      name    : 'port'
      message : 'Choose the port that you want to run your server at?'
      choices : ['5000', '80']
    ], (res) ->

      {siteName, watch, serve, newSite, uglify, port} = res

      return req('task.site') newSite  if newSite

      if serve
        server = require SERVER_FILE
        server siteName, parseInt port, 10

      gulp.src ''
        .pipe shell [
          "gulp #{unless watch then 'build ' else ''}--gulpfile ./site.#{siteName}/gulpfile.coffee  #{if uglify then '--uglify' else ''}"
        ]



# ERROR HANDLING

process.on 'uncaughtException', (err)->

  log 'red', "#{err.name}: #{err.message}"
  # console.error err
