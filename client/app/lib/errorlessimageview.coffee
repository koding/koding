kd                = require 'kd'
KDCustomHTMLView  = kd.CustomHTMLView

module.exports    = class ErrorlessImageView extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.tagName    = 'img'
    options.cssClass   = 'hidden'
    options.bind       = 'load error'
    options.attributes =
        width          : options.width
        height         : options.height

    super options, data


  error: ->

    @hide()

    return no
