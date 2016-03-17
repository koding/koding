gulp     = require 'gulp'
imagemin = require 'gulp-imagemin'
pngquant = require 'imagemin-pngquant'

{ BUILD_PATH, IMAGE_PATH } = require './helper.constants'

module.exports = ->

  gulp.src IMAGE_PATH
    .pipe imagemin
      progressive : on
      svgoPlugins : [ { removeViewBox : off } ]
      use         : [ pngquant() ]
    .pipe gulp.dest BUILD_PATH
