React = require 'react'

# WARNING: To be able to render this we need webpack configured with
# image-loader, url-loader.
#
# How to use:
# image1x = require 'app/sprites/1x/cc-error.png'
# image2x = require 'app/sprites/2x/cc-error.png'
# <Icon 1x={image1x} 2x={image2x} />

module.exports = Icon = (props) ->

  one = props['1x']
  two = props['2x']

  imgOne = new Image
  imgOne.src = one
  { naturalHeight: height, naturalWidth: width } = imgOne

  src = if global.devicePixelRatio >= 2 then two else one

  <span><img src={src} style={{height, width}} /></span>
