kd           = require 'kd'
React        = require 'react'
AppComponent = require './appcomponent'

###*
 * Bridge between KD and React. Finally. ~Umut
###
module.exports = class ShowcaseAppView extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = 'ShowcaseApp'

    super options, data

    # Since this class is not a React component and we are using this
    # dispatcher to send events to the Top level React component, so that it
    # can set its own state, and pass the props to its children.
    @_dispatcher = new kd.Object


  ###*
   * Takes a React Component and dispatches it after initializing it.
   *
   * @param {React.Component} component
  ###
  showReactComponent: (component) ->

    @_dispatcher.emit 'ShowComponent', React.createElement component


  ###*
   * To be implemented...
  ###
  showKDView: (component) ->
    console.error 'ShowcaseAppView::showKDView: not yet implemented'


  ###*
   * Initial render, render AppComponent, pass the dispatcher to it;
   * then append it into this view's dom element.
  ###
  viewAppended: ->

    React.render(
      React.createElement AppComponent, { dispatcher: @_dispatcher }
      @getElement()
    )


