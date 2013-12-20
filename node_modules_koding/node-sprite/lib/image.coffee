im = require "imagemagick"
checksum = require "./checksum"

class Image
  positionX: null
  positionY: null
  width: null
  height: null
  checksum: null
  constructor: (@filename, @path) ->
    @name = @filename.replace /\.(png|gif|jpg|jpeg)$/, ''
  readDimensions: (cb) ->
    checksum.file @file(), (err, sum) =>
      im.identify @file(), (err, img) =>
        unless err
          @width = img.width
          @height = img.height
          @checksum = sum
        cb(err)
  file: ->
    "#{@path}/#{@filename}"

module.exports = Image