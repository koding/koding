gulp           = require 'gulp'
spritesmith    = require 'gulp.spritesmith'

{ BUILD_PATH } = require './helper.constants'

module.exports = ->

  stream = gulp.src 'static/sprites@2x/**/*.png'
    .pipe spritesmith
      imgName   : 'sprite@2x.png'
      cssName   : 'sprite@2x.styl'
      imgPath   : '/a/out/images/sprite@2x.png'
      algorithm : 'binary-tree'
      padding   : 10
      cssFormat : 'stylus'
      cssVarMap : require('./helper.namestylusvars').bind stream, '__2x'

  stream.css
    .pipe gulp.dest './landing/styl/'

  stream.img
    .pipe gulp.dest "#{BUILD_PATH}/images/"

  return stream
