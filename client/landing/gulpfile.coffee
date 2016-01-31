fs      = require 'fs'
gulp    = require 'gulp'
shell   = require 'gulp-shell'
prompt  = require 'gulp-prompt'
argv    = require('minimist') process.argv
req     = (module) -> require "./gulptasks/#{module}"


# CREATE SITE FROM BOILERPLATE

gulp.task 'site', req 'task.site'




# BUILD

gulp.task 'build-all-sites', req 'task.build.all'


# ERROR HANDLING

process.on 'uncaughtException', (err)->

  log 'red', "#{err.name}: #{err.message}"
  # console.error err
