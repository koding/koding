gutil      = require 'gulp-util'
log        = (color, message) -> gutil.log gutil.colors[color] message
argv       = require('minimist') process.argv
devMode    = argv.devMode?

log = (color, message) -> gutil.log gutil.colors[color] message

module.exports =

  watchLogger : (color, watcher) ->

    watcher.on 'change', (event) -> log color, "file #{event.path} was #{event.type}"
