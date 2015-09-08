kd                = require 'kd'
KDCustomHTMLView  = kd.CustomHTMLView


module.exports = class SplitRegionPartView extends KDCustomHTMLView

  CSS_CLASS = 'show'

  constructor: (options = {}, data) ->

    options.cssClass  = kd.utils.curry 'region', options.direction

    super options, data

    @addSubView new KDCustomHTMLView
      tagName   : 'span'
      partial   : 'Drop to move source pane to this split'

    @addSubView @holder = new KDCustomHTMLView

