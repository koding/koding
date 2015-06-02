kd          = require 'kd'
React       = require 'app/react'
ReactBridge = require './reactbridge'


module.exports = class ReactView extends kd.CustomHTMLView

  constructor: (options, data) ->

    super options, data

    @_dispatcher = new kd.Object


  renderReact: ->

    console.error "#{@constructor.name}: needs to implement 'renderReact' method"


  setComponent: (component, props) ->

    @_dispatcher.emit 'SetComponent', React.createElement component, props


  viewAppended: ->

    bridgeOptions =
      dispatcher : @_dispatcher
      component  : @renderReact()

    bridge = @options.bridge or ReactBridge

    React.render(
      React.createElement(bridge, bridgeOptions),
      @getElement()
    )



