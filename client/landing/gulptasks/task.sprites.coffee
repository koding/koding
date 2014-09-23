gulp        = require 'gulp'
spritesmith = require 'gulp.spritesmith'
argv        = require('minimist') process.argv
site        = argv.site or 'landing'

{ BUILD_PATH } = require './helper.constants'

module.exports = (pixelRatio = 1) ->

  suffix = if pixelRatio > 1 then "__#{pixelRatio}x" else ''

  stream = gulp.src "./../#{site}/sprites@#{pixelRatio}x/**/*.png"
    .pipe spritesmith
      imgName   : "sprite@#{pixelRatio}x.png"
      cssName   : "sprite@#{pixelRatio}x.styl"
      imgPath   : "/a/#{site}/images/sprite@#{pixelRatio}x.png"
      algorithm : 'binary-tree'
      padding   : 5
      cssFormat : 'stylus'
      cssVarMap : require('./helper.namestylusvars').bind stream, suffix

  stream.css
    .pipe gulp.dest "./../#{site}/styl/"

  stream.img
    .pipe gulp.dest "#{BUILD_PATH}/images/"

  return stream
