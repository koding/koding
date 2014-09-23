gulp  = require 'gulp'
shell = require 'gulp-shell'
argv  = require('minimist') process.argv

{log} = require './helper.logger'


module.exports = ->

  exportDir = argv.exportDir

  unless exportDir

    log 'yellow', "nothing exported."
    return

  cmd = "cp -Rf #{__dirname}/#{BUILD_PATH} #{exportDir}"

  log 'green', "Exporting to: #{exportDir}"

  gulp.src ''
    .pipe shell [cmd]
