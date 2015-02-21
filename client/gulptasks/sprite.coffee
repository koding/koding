gulp           = require 'gulp'
spritesmith    = require 'gulp.spritesmith'
notify         = require 'gulp-notify'
nameHelper     = (folder, pixelRatio, sprite) ->

  # this is bad, but stylus throws when you have dots in variable names
  # we shouldn't use dots in image file names - SY
  if /\./.test(sprite.name)
    console.error "ERROR: Dots in sprite names cause problems, pls fix: #{sprite.name}"

  name        = sprite.name.replace /\./g, '_'
  sprite.name = "#{pixelRatio}x_#{folder}_#{name}";

  return sprite

module.exports = (folder, pixelRatio) ->

  stream = gulp.src "./#{folder}/lib/sprites/#{pixelRatio}x/**/*.png"
    # .pipe notify
    #   title    : "Sprites generated"
    #   message  : "#{pixelRatio}x #{folder}"
    #   icon     : "#{__dirname}/../assets/blueprint.png"
    #   onLast   : yes
    .pipe spritesmith
      imgName   : "#{folder}@#{pixelRatio}x.png"
      cssName   : "sprite@#{pixelRatio}x.styl"
      imgPath   : "/a/p/p/#{folder}@#{pixelRatio}x.png"
      algorithm : 'binary-tree'
      padding   : 5
      cssFormat : 'stylus'
      cssVarMap : nameHelper.bind stream, folder, pixelRatio

  return stream
