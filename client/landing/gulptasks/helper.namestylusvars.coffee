{ log } = require './helper.logger'

module.exports = (suffix, sprite) ->

  arr   = sprite.source_image.split '/'
  group = arr[arr.length - 2]

  # this is bad, but stylus throws when you have dots in variable names
  # we shouldn't use dots in image file names - SY
  if /\./.test(sprite.name)
    log 'red', "ERROR: Dots in sprite names cause problems, pls fix: #{sprite.name}"

  name        = sprite.name.replace /\./g, '_'
  sprite.name = "#{group}_#{name}#{suffix}"

  return sprite
