kd                      = require 'kd'
KDCustomHTMLView        = kd.CustomHTMLView
SplitRegionHandlerView  = require './splitregionhandlerview'


module.exports = class SplitRegionView extends KDCustomHTMLView


  constructor: (options = {}, data) ->

    options.cssClass  = kd.utils.curry 'split-regions', options.cssClass

    super options, data

    @createViews()


  createViews: ->

    directions      = [ 'top', 'right', 'bottom', 'left' ]

    @addSubView @representation = new KDCustomHTMLView { cssClass : 'representation' }
    @addSubView @handler        = new KDCustomHTMLView { cssClass : 'handler' }

    for direction in directions
      # Create representation view.
      view = @createRepView direction
      @representation.addSubView view

      # Create handler view.
      handlerView = new SplitRegionHandlerView { direction, view }
      @handler.addSubView handlerView

      handlerView.on 'TabDropped', (direction) =>
        @emit 'TabDropped', direction


  ###*
   * Create representation view
   * @param {string} direction
  ###
  createRepView: (direction) ->

    return new KDCustomHTMLView
      cssClass  : kd.utils.curry 'region', direction
      tagName   : 'div'
      partial   : '<span>Drop to move source pane to this split.</span>'
