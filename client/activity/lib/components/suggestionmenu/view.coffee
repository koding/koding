kd               = require 'kd'
React            = require 'kd-react'
ReactView        = require 'app/react/reactview'
KDCustomHTMLView = kd.CustomHTMLView
ActivityFlux     = require 'activity/flux'
SuggestionMenu   = require './index'


module.exports = class SuggestionMenuView extends KDCustomHTMLView

  constructor: (options, data) ->

    super options, data

    @isListeningToWindow = no
    @on 'ReceivedClickElsewhere', @bound 'handleClickElsewhere'


  viewAppended: ReactView::viewAppended


  renderReact: ->
    <SuggestionMenu checkVisibility={@bound 'checkVisibility'} />


  checkVisibility: (isVisible) ->

    { windowController } = kd.singletons
    if isVisible
      unless @isListeningToWindow
        windowController.addLayer this
        @isListeningToWindow = yes
    else
      windowController.removeLayer this
      @isListeningToWindow = no


  handleClickElsewhere: -> ActivityFlux.actions.suggestions.changeVisibility yes