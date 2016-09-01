kd              = require 'kd'
KDView          = kd.View
getCopyShortcut = require 'app/util/getCopyShortcut'

require './styl/copytooltipview.styl'


module.exports = class CopyTooltipView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass        = kd.utils.curry 'copy-tooltip-view', options.cssClass
    options.childView      ?= new KDView

    options.tooltip             or= {}
    options.tooltip.sticky      or= yes
    options.tooltip.title        ?= "Press #{getCopyShortcut()} to copy"
    options.tooltip.placement    ?= 'above'
    options.tooltip.events       ?= ['mouseleave']

    super options, data

    @addSubView options.childView


  createTooltip: ->

    @setTooltip @options.tooltip


  showTooltip:  ->

    @createTooltip()  unless @tooltip
    @tooltip.show()
