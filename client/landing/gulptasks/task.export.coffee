gulp   = require 'gulp'
shell  = require 'gulp-shell'
argv   = require('minimist') process.argv
notify = require 'gulp-notify'

{ log }        = require './helper.logger'
{ BUILD_PATH } = require './helper.constants'

module.exports = ->

  exportDir = argv.exportDir

  unless exportDir

    log 'yellow', 'nothing exported.'
    return

  cmds = [
    "rsync -av #{BUILD_PATH}/ #{exportDir}"
    "\necho 'Landing page export finished!'"
  ]

  gulp.src ''
    .pipe shell cmds
    .pipe notify 'files exported!'
