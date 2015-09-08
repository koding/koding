kd                      = require 'kd'
KDCustomHTMLView        = kd.CustomHTMLView
SplitRegionPartView     = require './splitregionpartview'
SplitRegionHandlerView  = require './splitregionhandlerview'


module.exports = class SplitRegionView extends KDCustomHTMLView


  constructor: (options = {}, data) ->

    options.cssClass  = kd.utils.curry 'split-regions', options.cssClass

    super options, data

    @createRepresentationLayer()
    @createHandlerLayer()


  createRepresentationLayer: ->

    @representation = new KDCustomHTMLView
      cssClass  : 'representation'

    @representation.addSubView @rTop    = new SplitRegionPartView direction : 'top'
    @representation.addSubView @rRight  = new SplitRegionPartView direction : 'right'
    @representation.addSubView @rBottom = new SplitRegionPartView direction : 'bottom'
    @representation.addSubView @rLeft   = new SplitRegionPartView direction : 'left'

    @addSubView @representation


  createHandlerLayer: ->

    @handler = new KDCustomHTMLView
      cssClass    : 'handler'

    @handler.addSubView @hTop    = new SplitRegionHandlerView
      direction   : 'top'
      view        : @rTop

    @handler.addSubView @hRight  = new SplitRegionHandlerView
      direction   : 'right'
      view        : @rRight

    @handler.addSubView @hBottom = new SplitRegionHandlerView
      direction   : 'bottom'
      view        : @rBottom

    @handler.addSubView @hLeft   = new SplitRegionHandlerView
      direction   : 'left'
      view        : @rLeft

    @addSubView @handler

    for item in @handler.subViews
      item.on 'TabDropped', (direction) =>
        @emit 'TabDropped', direction

