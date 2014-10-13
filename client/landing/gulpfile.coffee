fs      = require 'fs'
gulp    = require 'gulp'
shell   = require 'gulp-shell'
prompt  = require 'gulp-prompt'
nodemon = require 'gulp-nodemon'
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
    .filter (folder) -> folder.search(/^site\./) is 0
    .map (folder) -> folder.replace 'site.', ''

  firstOptions = ['Create a new site', 'Build an existing site']

  gulp.src ''
    .pipe prompt.prompt [
      type    : 'list'
      name    : 'createOrBuild'
      message : 'Would you like to create a new site or build an existing one?'
      choices : firstOptions
    ,
      when    : (answer) -> answer.createOrBuild is firstOptions[0]
      type    : 'input'
      name    : 'newSite'
      message : 'Type a name for the new site:'
    ,
      when    : (answer) -> answer.createOrBuild is firstOptions[1]
      type    : 'list'
      name    : 'siteName'
      message : 'Which site would you like to build?'
      choices : sites
    ,
      when    : (answer) -> answer.siteName
      type    : 'confirm'
      name    : 'uglify'
      default : no
      message : 'Would you like to uglify javascript?'
    ,
      when    : (answer) -> answer.siteName
      type    : 'confirm'
      name    : 'watch'
      message : 'Would you like to watch for changes?'
    ,
      when    : (answer)-> answer.watch
      type    : 'confirm'
      name    : 'serve'
      message : 'Would you like to run the server?'
    ], (res) ->

      console.log '\n'

      {siteName, watch, serve, newSite, uglify} = res

      return req('task.site') newSite  if newSite

      if serve
        server = require SERVER_FILE
        server siteName

      gulp.src ''
        .pipe shell [
          "gulp #{unless watch then 'build ' else ''}--gulpfile ./site.#{siteName}/gulpfile.coffee  #{if uglify then '--uglify' else ''}"
        ]



# ERROR HANDLING

process.on 'uncaughtException', (err)->

  log 'red', "#{err.name}: #{err.message}"
  # console.error err
