kd             = require 'kd'
React          = require 'kd-react'
ReactView      = require 'app/react/reactview'
ActivityFlux   = require 'activity/flux'
SuggestionMenu = require './index'
groupifyLink   = require 'app/util/groupifyLink'


module.exports = class SuggestionMenuView extends ReactView

  constructor: (options, data) ->

    super options, data

    @isListeningToWindow = no
    @isVisible           = no
    @on 'ReceivedClickElsewhere', @bound 'handleClickElsewhere'


  renderReact: ->

    <SuggestionMenu
      checkVisibility = { @bound 'checkVisibility' }
      onSubmit        = { @bound 'handleSubmit' }
      onItemConfirmed = { @bound 'confirmSelectedItem' }
    />


  checkVisibility: (isVisible) ->

    { windowController } = kd.singletons
    if isVisible
      unless @isListeningToWindow
        windowController.addLayer this
        @isListeningToWindow = yes
    else
      windowController.removeLayer this
      @isListeningToWindow = no

    @isVisible = isVisible


  handleClickElsewhere: -> ActivityFlux.actions.suggestions.setVisibility no


  handleSubmit: (e) ->

    kd.utils.stopDOMEvent e
    @emit 'SubmitRequested'


  moveToNextIndex: -> ActivityFlux.actions.suggestions.moveToNextIndex()


  moveToPrevIndex: -> ActivityFlux.actions.suggestions.moveToPrevIndex()


  confirmSelectedItem: ->

    { getters }         = ActivityFlux
    { reactor, router } = kd.singletons
    selectedItem        = reactor.evaluate getters.currentSuggestionsSelectedItem
    return  unless selectedItem

    slug = selectedItem.getIn ['message', 'slug']
    router.handleRoute groupifyLink "/Activity/Post/#{slug}"
