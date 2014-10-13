gulp   = require 'gulp'
rimraf = require 'gulp-rimraf'

{ BUILD_PATH } = require './helper.constants'

module.exports = ->

  gulp.src "#{__dirname}/../static/a/site.boilerplate/js/pistachio.js"
    .pipe gulp.dest "#{BUILD_PATH}/js"
