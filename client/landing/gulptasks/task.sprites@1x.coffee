gulp           = require 'gulp'
spritesmith    = require 'gulp.spritesmith'

{ BUILD_PATH } = require './helper.constants'

module.exports = ->

  stream = gulp.src 'static/sprites@1x/**/*.png'
    .pipe spritesmith
      imgName   : 'sprite@1x.png'
      cssName   : 'sprite@1x.styl'
      imgPath   : '/a/out/images/sprite@1x.png'
      algorithm : 'binary-tree'
      padding   : 5
      cssFormat : 'stylus'
      cssVarMap : require('./helper.namestylusvars').bind stream, ''

  stream.css
    .pipe gulp.dest './landing/styl/'

  stream.img
    .pipe gulp.dest "#{BUILD_PATH}/images/"

  return stream
