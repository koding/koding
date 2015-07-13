actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

module.exports = class SuggestionsStateStore extends KodingFluxStore

  getInitialState: -> toImmutable { accessible: yes, visible: yes }

  initialize: ->

    @on actions.SET_SUGGESTIONS_VISIBILITY, @setVisibility
    @on actions.SET_SUGGESTIONS_ACCESS, @changeAccess


  setVisibility: (currentState, { visible }) ->

    currentState.set 'visible', visible


  changeAccess: (currentState, { accessible }) ->

    currentState.set 'accessible', accessible