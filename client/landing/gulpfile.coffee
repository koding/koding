gulp    = require 'gulp'
req     = (module) -> require "./gulptasks/#{module}"
{ log } = req 'helper.logger'


# BUILD

gulp.task 'build-all-sites', req 'task.build.all'


# ERROR HANDLING

process.on 'uncaughtException', (err) ->

  log 'red', "#{err.name}: #{err.message}"
