gulp   = require 'gulp'

{ BUILD_PATH, INDEX_PATH } = require './helper.constants'

module.exports = ->

  gulp.src INDEX_PATH
    .pipe gulp.dest "#{BUILD_PATH}"
