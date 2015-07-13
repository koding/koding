kd               = require 'kd'
React            = require 'kd-react'
ReactView        = require 'app/react/reactview'
ActivityFlux     = require 'activity/flux'
SuggestionMenu   = require './index'

module.exports = class SuggestionMenuView extends ReactView

  constructor: (options, data) ->

    super options, data

    @isListeningToWindow = no
    @on 'ReceivedClickElsewhere', @bound 'handleClickElsewhere'


  renderReact: ->

    <SuggestionMenu checkVisibility={@bound 'checkVisibility'} onSubmit={@bound 'handleSubmit'} />


  checkVisibility: (isVisible) ->

    { windowController } = kd.singletons
    if isVisible
      unless @isListeningToWindow
        windowController.addLayer this
        @isListeningToWindow = yes
    else
      windowController.removeLayer this
      @isListeningToWindow = no


  handleClickElsewhere: -> ActivityFlux.actions.suggestions.setVisibility no


  handleSubmit: (e) ->

    e.preventDefault()
    @emit 'SubmitRequested'