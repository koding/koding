kd                = require 'kd'

generatePassword  = require 'app/util/generatePassword'


module.exports = class IDEPane extends kd.View


  constructor: (options = {}, data) ->

    options.cssClass  = kd.utils.curry 'pane', options.cssClass

    super options, data

    @hash = options.hash or generatePassword 64, no

  setFocus: (state) ->

  setScrollMarginTop: (top) -> @aceView?.ace?.editor.renderer.setScrollMargin 0, top, 0, 0
