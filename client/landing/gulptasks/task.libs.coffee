gulp   = require 'gulp'
concat = require 'gulp-concat'

{ BUILD_PATH, LIBS_PATH } = require './helper.constants'

module.exports = ->

  gulp.src LIBS_PATH
    .pipe concat 'libs.js'
    .pipe gulp.dest "#{BUILD_PATH}/js"
