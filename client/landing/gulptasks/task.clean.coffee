gulp   = require 'gulp'
rimraf = require 'gulp-rimraf'

{ BUILD_PATH } = require './helper.constants'

module.exports = ->
  gulp.src [BUILD_PATH], read: no
    .pipe rimraf force: yes
